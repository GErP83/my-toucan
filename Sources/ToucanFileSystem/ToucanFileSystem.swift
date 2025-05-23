//
//  ToucanFileSystem.swift
//  Toucan
//
//  Created by Binary Birds on 2025. 04. 17..

import Foundation
import FileManagerKit
import ToucanModels

/// A structured filesystem accessor for locating various types of files used in the Toucan content pipeline.
public struct ToucanFileSystem {

    // MARK: - File Locators

    /// Locates configuration files typically named `"config.yml"` or `"config.yaml"`.
    public let configLocator: FileLocator

    /// Locates site settings files, commonly named `"site.yml"` or `"site.yaml"`.
    public let settingsLocator: FileLocator

    /// Locates static assets like images, JS, or CSS files under the project directory.
    public let assetLocator: AssetLocator

    /// Locates pipeline configuration files, usually for defining content transformations or build steps.
    public let pipelineLocator: FileLocator

    /// Locates content definition and block directive YAML files.
    public let ymlFileLocator: FileLocator

    /// Locates raw Markdown or content source files.
    public let rawContentLocator: RawContentLocator

    /// Locates template files used for rendering HTML output.
    public let templateLocator: TemplateLocator

    // MARK: - Initializer

    /// Initializes all locators with a shared `FileManagerKit` instance.
    ///
    /// - Parameter fileManager: A file manager abstraction used by each internal locator.
    public init(fileManager: FileManagerKit) {
        self.configLocator = FileLocator(
            fileManager: fileManager,
            name: "config",
            extensions: ["yml", "yaml"]
        )
        self.settingsLocator = FileLocator(
            fileManager: fileManager,
            name: "site",
            extensions: ["yml", "yaml"]
        )
        self.assetLocator = AssetLocator(fileManager: fileManager)
        self.pipelineLocator = FileLocator(
            fileManager: fileManager,
            extensions: ["yml", "yaml"]
        )
        self.ymlFileLocator = FileLocator(
            fileManager: fileManager,
            extensions: ["yml", "yaml"]
        )
        self.rawContentLocator = RawContentLocator(fileManager: fileManager)
        self.templateLocator = TemplateLocator(fileManager: fileManager)
    }
}
