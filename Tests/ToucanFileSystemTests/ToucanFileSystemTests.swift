//
//  ToucanFileSystemTests.swift
//  Toucan
//
//  Created by Binary Birds on 2025. 04. 01..

import Testing
import Foundation
import ToucanModels
@testable import ToucanFileSystem
@testable import FileManagerKitTesting

@Suite(.serialized)
struct ToucanFileSystemTests {

    @Test()
    func fileSystem_NoFiles() async throws {
        try FileManagerPlayground {
            Directory("foo") {
                Directory("bar")
                Directory("baz")
            }
        }
        .test {
            let url = $1.appending(path: "foo/bar/")
            let overrideUrl = $1.appending(path: "foo/bar/")
            let fs = ToucanFileSystem(fileManager: $0)

            #expect(fs.rawContentLocator.locate(at: url).isEmpty)
            #expect(fs.rawContentLocator.locate(at: url).isEmpty)
            #expect(fs.ymlFileLocator.locate(at: url).isEmpty)
            #expect(
                fs.templateLocator.locate(at: url, overrides: overrideUrl)
                    .isEmpty
            )
        }
    }

    @Test()
    func fileSystem_Typical() async throws {
        try FileManagerPlayground {
            Directory("src") {
                Directory("assets") {
                    "CNAME"
                    Directory("icons") {
                        "favicon.png"
                    }
                }

                Directory("contents") {
                    "index.md"
                    Directory("assets") {
                        "main.js"
                    }
                    Directory("404") {
                        "index.md"
                    }

                    Directory("blog") {
                        "noindex.yml"
                        Directory("authors") {
                            "index.md"
                        }
                    }
                    Directory("redirects") {
                        "noindex.yml"
                        Directory("home-old") {
                            "index.md"
                        }
                    }
                }
                Directory("types") {
                    "author.yml"
                    "post.yml"
                    "redirect.yml"
                }
                Directory("blocks") {
                    "link.yml"
                }
                Directory("themes") {
                    Directory("default") {
                        Directory("assets") {
                            Directory("css") {
                                "base.css"
                            }
                        }
                        Directory("templates") {
                            "html.mustache"
                            "redirect.mustache"
                            Directory("partials") {
                                "navigation.mustache"
                                "footer.mustache"
                                Directory("blog") {
                                    "author.mustache"
                                    "post.mustache"
                                }
                                Directory("pages") {
                                    "home.mustache"
                                    "404.mustache"
                                    "default.mustache"
                                }
                            }
                            Directory("blog") {
                                "posts.mustache"
                                Directory("post") {
                                    "default.mustache"
                                }
                            }
                        }
                    }
                    Directory("overrides") {
                        Directory("templates") {
                            Directory("blog") {
                                "posts.mustache"
                            }
                        }
                    }
                }
            }
        }
        .test {
            let fs = ToucanFileSystem(fileManager: $0)
            let contentsUrl = $1.appending(path: "src/contents/")

            let rawContentLocations = fs.rawContentLocator.locate(
                at: contentsUrl
            )

            let expectation: [RawContentLocation] = [
                .init(slug: "", md: "index.md"),
                .init(slug: "404", md: "404/index.md"),
                .init(slug: "authors", md: "blog/authors/index.md"),
                .init(
                    slug: "home-old",
                    md: "redirects/home-old/index.md"
                ),
            ]
            .sorted { $0.slug < $1.slug }

            #expect(
                rawContentLocations.sorted { $0.slug < $1.slug } == expectation
            )

            let typesUrl = $1.appending(path: "src/types/")

            let contentTypes = fs.ymlFileLocator.locate(at: typesUrl)
            #expect(
                contentTypes.sorted { $0 < $1 }
                    == [
                        "author.yml",
                        "post.yml",
                        "redirect.yml",
                    ]
                    .sorted { $0 < $1 }
            )

            let blocksUrl = $1.appending(path: "src/blocks/")
            let blocks = fs.ymlFileLocator.locate(at: blocksUrl)

            #expect(
                blocks.sorted { $0 < $1 }
                    == [
                        "link.yml"
                    ]
                    .sorted { $0 < $1 }
            )

            let templatesUrl = $1.appending(
                path: "src/themes/default/templates/"
            )
            let templatesOverridesUrl = $1.appending(
                path: "src/themes/overrides/templates/"
            )

            let templates = fs.templateLocator.locate(
                at: templatesUrl,
                overrides: templatesOverridesUrl
            )

            #expect(
                templates
                    == [
                        .init(
                            id: "blog.post.default",
                            path: "blog/post/default.mustache"
                        ),
                        .init(id: "blog.posts", path: "blog/posts.mustache"),
                        .init(id: "html", path: "html.mustache"),
                        .init(
                            id: "partials.blog.author",
                            path: "partials/blog/author.mustache"
                        ),
                        .init(
                            id: "partials.blog.post",
                            path: "partials/blog/post.mustache"
                        ),
                        .init(
                            id: "partials.footer",
                            path: "partials/footer.mustache"
                        ),
                        .init(
                            id: "partials.navigation",
                            path: "partials/navigation.mustache"
                        ),
                        .init(
                            id: "partials.pages.404",
                            path: "partials/pages/404.mustache"
                        ),
                        .init(
                            id: "partials.pages.default",
                            path: "partials/pages/default.mustache"
                        ),
                        .init(
                            id: "partials.pages.home",
                            path: "partials/pages/home.mustache"
                        ),
                        .init(id: "redirect", path: "redirect.mustache"),
                    ]
                    .sorted { $0.path < $1.path }
            )
        }
    }

    @Test()
    func fileSystem_SettingsLocator() async throws {
        try FileManagerPlayground {
            Directory("src") {
                Directory("contents") {
                    "site.yml"
                    "site.yaml"
                    "index.yml"
                    "index.md"
                }
            }
        }
        .test {
            let fs = ToucanFileSystem(fileManager: $0)
            let url = $1.appending(path: "src/contents/")
            let locations = fs.settingsLocator.locate(at: url)

            #expect(locations.sorted() == ["site.yaml", "site.yml"])
        }
    }

}
