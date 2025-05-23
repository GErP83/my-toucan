//
//  SettingsLoaderTestSuite.swift
//  Toucan
//
//  Created by Viasz-Kádi Ferenc on 2025. 02. 28..
//

import Foundation
import Testing
import ToucanModels
import ToucanTesting
import Logging
import FileManagerKitTesting
import ToucanSerialization
@testable import ToucanSource
@testable import ToucanSDK
@testable import ToucanFileSystem

@Suite
struct SettingsLoaderTestSuite {

    @Test
    func basicSettings() throws {
        let logger = Logger(label: "SettingsLoaderTestSuite")
        try FileManagerPlayground {
            Directory("src") {
                File(
                    "site.yml",
                    string: """
                        baseUrl: http://localhost:8080/
                        name: Test
                        """
                )
            }
        }
        .test {
            let url = $1.appending(path: "src/")
            let loader = SettingsLoader(
                url: url,
                baseUrl: nil,
                locations: [
                    "site.yml"
                ],
                encoder: ToucanYAMLEncoder(),
                decoder: ToucanYAMLDecoder(),
                logger: logger
            )
            let result = try loader.load()
            let expectation = Settings(
                baseUrl: "http://localhost:8080/",
                name: "Test",
                locale: "en-US",
                timeZone: "UTC",
                userDefined: [:]
            )
            #expect(result == expectation)
        }
    }

    @Test
    func baseUrlOverride() throws {
        let logger = Logger(label: "SettingsLoaderTestSuite")
        try FileManagerPlayground {
            Directory("src") {
                File(
                    "site.yml",
                    string: """
                        baseUrl: http://localhost:8080/
                        name: Test
                        """
                )
            }
        }
        .test {
            let url = $1.appending(path: "src/")
            let loader = SettingsLoader(
                url: url,
                baseUrl: "http://localhost:3000",
                locations: [
                    "site.yml"
                ],
                encoder: ToucanYAMLEncoder(),
                decoder: ToucanYAMLDecoder(),
                logger: logger
            )
            let result = try loader.load()
            let expectation = Settings(
                baseUrl: "http://localhost:3000/",
                name: "Test",
                locale: "en-US",
                timeZone: "UTC",
                userDefined: [:]
            )
            #expect(result == expectation)
        }
    }
}
