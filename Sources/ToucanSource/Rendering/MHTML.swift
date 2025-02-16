//
//  File.swift
//  toucan
//
//  Created by Tibor Bodecs on 2025. 02. 16..
//

import Foundation
import Mustache
import Logging

extension String {

    func minifyHTML() -> Self {
        self
    }
}

public struct MustacheToHTMLRenderer {

    public enum Error: Swift.Error {
        case missingTemplate(String)
    }

    private let library: MustacheLibrary
    private let ids: [String]

    init(
        templatesUrl: URL,
        overridesUrl: URL,
        logger: Logger
    ) throws {
        var templates: [String: MustacheTemplate] = [:]
        for (id, template) in try Self.loadTemplates(at: templatesUrl) {
            templates[id] = template
        }
        for (id, template) in try Self.loadTemplates(at: overridesUrl) {
            templates[id] = template
        }

        self.library = MustacheLibrary(templates: templates)
        self.ids = Array(templates.keys)

        logger.trace(
            "Available templates: \(ids.sorted().map { "`\($0)`" }.joined(separator: ", "))"
        )
    }

    // MARK: -

    static func loadTemplates(
        at templatesUrl: URL
    ) throws -> [String: MustacheTemplate] {
        let ext = "mustache"
        var templates: [String: MustacheTemplate] = [:]
        if let dirContents = FileManager.default.enumerator(
            at: templatesUrl,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) {
            for case let url as URL in dirContents
            where url.pathExtension == ext {
                var relativePathComponents = url.pathComponents.dropFirst(
                    templatesUrl.pathComponents.count
                )
                let name = String(
                    relativePathComponents.removeLast()
                        .dropLast(".\(ext)".count)
                )
                relativePathComponents.append(name)
                let id = relativePathComponents.joined(separator: ".")
                templates[id] = try MustacheTemplate(
                    string: .init(contentsOf: url)
                )
            }
        }
        return templates
    }

    // MARK: -

    func render(
        template: String,
        with object: Any,
        to destination: URL
    ) throws {
        guard self.ids.contains(template) else {
            throw Error.missingTemplate(template)
        }
        try library.render(object, withTemplate: template)?
            .write(
                to: destination,
                atomically: true,
                encoding: .utf8
            )
    }
}
