//
//  RawContentLoader.swift
//  Toucan
//
//  Created by Viasz-Kádi Ferenc on 2025. 03. 03..
//

import Foundation
import Logging
import ToucanModels
import ToucanFileSystem
import ToucanSource
import FileManagerKit
import ToucanSerialization

/// A utility structure responsible for loading and parsing raw content files
public struct RawContentLoader {

    /// Represents errors that can occur during the raw content loading process.
    /// - `invalidFrontMatter`: Indicates that the front matter could not be parsed correctly at the specified file path.
    public enum Error: Swift.Error {
        case invalidFrontMatter(path: String)
    }

    /// The URL of the source files.
    let url: URL

    /// Content file paths
    let locations: [RawContentLocation]

    /// Source configuration.
    let sourceConfig: SourceConfig

    /// A parser responsible for processing front matter data.
    let frontMatterParser: FrontMatterParser

    /// A file manager instance for handling file operations.
    let fileManager: FileManagerKit

    /// The logger instance
    let logger: Logger

    // baseUrl for image asset resolve
    let baseUrl: String

    /// Loads raw content items from a set of predefined locations.
    ///
    /// This function iterates over a collection of locations, resolves each into a `RawContent` item,
    /// and collects them into an array.
    ///
    /// - Returns: An array of `RawContent` objects representing the loaded items.
    /// - Throws: An error if any of the content items cannot be resolved.
    func load() throws -> [RawContent] {
        logger.debug("Loading raw contents at: `\(url.absoluteString)`")

        var items: [RawContent] = []
        for location in locations {
            let item = try resolveItem(location)
            items.append(item)
        }

        return items
    }
}

private extension RawContentLoader {

    func resolveItem(_ location: RawContentLocation) throws -> RawContent {
        var frontMatter: [String: AnyCodable] = [:]
        var markdown: String?
        var path: String?
        var modificationDate: Date?

        typealias Resolver = (String) throws -> (
            frontMatter: [String: AnyCodable],
            markdown: String
        )

        let orderedPathResolvers:
            [(
                primaryPath: String?,
                fallbackPath: String?,
                resolver: Resolver,
                isMarkdown: Bool
            )] = [
                (location.markdown, location.md, resolveMarkdown, true),
                (location.yaml, location.yml, resolveYaml, false),
            ]

        for (
            primaryPath,
            fallbackPath,
            resolver,
            isMarkdown
        ) in orderedPathResolvers {
            if let filePath = primaryPath ?? fallbackPath {
                do {
                    let result = try resolver(filePath)

                    frontMatter = frontMatter.recursivelyMerged(
                        with: result.frontMatter
                    )

                    /// Set contents if its a md resolver
                    if isMarkdown {
                        markdown = result.markdown
                    }
                    /// Set path if its a md resolver or a yml resolver but there is no path yet
                    if isMarkdown || path == nil {
                        path = filePath
                    }
                    /// Set modification date if there is no date yet (either md or yml) or if its more recent
                    let url = url.appendingPathComponent(path ?? "")
                    if let existingDate = modificationDate {
                        modificationDate = max(
                            existingDate,
                            try fileManager.modificationDate(at: url)
                        )
                    }
                    else {
                        modificationDate = try fileManager.modificationDate(
                            at: url
                        )
                    }
                }
                catch ToucanDecoderError.decoding(_, _) {
                    throw Error.invalidFrontMatter(path: filePath)
                }
            }
        }

        let url = url.appendingPathComponent(path ?? "")
        let assetLocator = AssetLocator(fileManager: fileManager)
        let assetsPath = sourceConfig.config.contents.assets.path
        let assetsUrl = url.deletingLastPathComponent()
            .appending(
                path: assetsPath
            )
        let assetLocations = assetLocator.locate(at: assetsUrl)

        // TODO: check if we need this or not.
        frontMatter["image"] = .init(
            resolveImage(
                frontMatter: frontMatter,
                assetsPath: assetsPath,
                assetLocations: assetLocations,
                slug: .init(value: location.slug)
            )
        )

        return RawContent(
            origin: .init(path: path ?? "", slug: location.slug),
            frontMatter: frontMatter,
            markdown: markdown ?? "",
            lastModificationDate: (modificationDate ?? Date())
                .timeIntervalSince1970,
            assets: assetLocations
        )
    }

    func loadItem(at url: URL) throws -> String {
        try url.loadContents()
    }
}

extension RawContentLoader {

    func resolveMarkdown(
        at path: String
    ) throws -> (frontMatter: [String: AnyCodable], markdown: String) {
        let url = url.appendingPathComponent(path)
        let rawContents = try loadItem(at: url)
        return (
            frontMatter: try frontMatterParser.parse(rawContents),
            markdown: rawContents.dropFrontMatter()
        )
    }

    func resolveYaml(
        at path: String
    ) throws -> (frontMatter: [String: AnyCodable], markdown: String) {
        let url = url.appendingPathComponent(path)
        let rawContents = try loadItem(at: url)
        return (
            frontMatter: try frontMatterParser.decoder.decode(
                [String: AnyCodable].self,
                from: rawContents.dataValue()
            ),
            markdown: ""
        )
    }

    func resolveImage(
        frontMatter: [String: AnyCodable],
        assetsPath: String,
        assetLocations: [String],
        slug: Slug,
        imageKey: String = "image"
    ) -> String? {

        if let imageValue = frontMatter[imageKey]?.stringValue() {
            if imageValue.hasPrefix("/") {
                return .init(
                    "\(baseUrl)\(baseUrl.suffixForPath())\(imageValue.dropFirst())"
                )
            }
            else {
                return .init(
                    imageValue.resolveAsset(
                        baseUrl: baseUrl,
                        assetsPath: assetsPath,
                        slug: slug
                    )
                )
            }
        }

        return nil
    }

}
