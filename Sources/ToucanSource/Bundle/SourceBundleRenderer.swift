//
//  SourceBundleRenderer.swift
//  Toucan
//
//  Created by Viasz-Kádi Ferenc on 2025. 03. 25..
//

import Foundation
import ToucanModels
import ToucanContent
import FileManagerKit
import Logging
import ToucanInfo

/// Responsible for rendering the entire site bundle based on the `SourceBundle` configuration.
///
/// It processes content pipelines using the configured engine (Mustache, JSON, etc.),
/// resolves content and site-level context, and outputs rendered content using templates
/// or encoded formats.
public struct SourceBundleRenderer {

    /// Site configuration + all raw content
    let sourceBundle: SourceBundle
    /// Generator metadata (e.g., version, name)
    let generatorInfo: GeneratorInfo
    /// Date formatters used across pipelines
    let formatters: [String: DateFormatter]
    /// File system abstraction
    let fileManager: FileManagerKit
    /// Logger for warnings and errors
    let logger: Logger
    /// Cache
    var contentContextCache: [String: [String: AnyCodable]] = [:]

    /// Initializes a renderer from a source bundle.
    ///
    /// - Parameters:
    ///   - sourceBundle: The structured bundle containing settings, pipelines, and contents.
    ///   - generatorInfo: Info about the content generator (defaults to `.current`).
    ///   - fileManager: Filesystem API for use during rendering.
    ///   - logger: Logger for reporting issues or metrics.
    public init(
        sourceBundle: SourceBundle,
        generatorInfo: GeneratorInfo = .current,
        fileManager: FileManagerKit,
        logger: Logger
    ) {
        self.sourceBundle = sourceBundle
        self.generatorInfo = generatorInfo
        self.fileManager = fileManager
        self.logger = logger
        self.formatters = Self.prepareFormatters(sourceBundle)
    }

    // MARK: -

    /// Returns the site context based on the source bundle settings and the generator info
    private func getSiteContext(
        for now: TimeInterval
    ) -> [String: AnyCodable] {
        sourceBundle.settings.userDefined.recursivelyMerged(
            with: [
                "baseUrl": .init(sourceBundle.settings.baseUrl),
                "name": .init(sourceBundle.settings.name),
                "locale": .init(sourceBundle.settings.locale),
                "timeZone": .init(sourceBundle.settings.timeZone),
                "generation": .init(now.toDateFormats(formatters: formatters)),
                "generator": .init(generatorInfo),
            ]
        )
    }

    /// Returns the last content update based on the pipeline config
    private func getLastContentUpdate(
        contents: [Content],
        pipeline: Pipeline,
        now: TimeInterval
    ) -> TimeInterval? {
        var updateTypes = contents.map(\.definition.id)
        if !pipeline.contentTypes.lastUpdate.isEmpty {
            updateTypes = updateTypes.filter {
                pipeline.contentTypes.lastUpdate.contains($0)
            }
        }
        return
            updateTypes.compactMap {
                let items = contents.run(
                    query: .init(
                        contentType: $0,
                        scope: nil,
                        limit: 1,
                        orderBy: [
                            .init(
                                key: "lastUpdate",
                                direction: .desc
                            )
                        ]
                    ),
                    now: now
                )
                return items.first?.rawValue.lastModificationDate
            }
            .sorted(by: >).first
    }

    /// Starts rendering the source bundle based on current time and pipeline configuration.
    ///
    /// - Parameter now: Current date, used for generation timestamps.
    /// - Returns: A list of rendered `PipelineResult`s.
    /// - Throws: Rendering or encoding-related errors.
    public mutating func render(
        now: Date
    ) throws -> [PipelineResult] {
        let now = now.timeIntervalSince1970
        var siteContext = getSiteContext(for: now)
        var results: [PipelineResult] = []
        let iteratorResolver = ContentIteratorResolver(
            baseUrl: sourceBundle.settings.baseUrl,
            now: now
        )

        let executor = AssetBehaviorExecutor(sourceBundle: sourceBundle)

        for pipeline in sourceBundle.pipelines {

            let pipelineFormatters = pipeline.dataTypes.date.dateFormats
                .mapValues {
                    sourceBundle.settings.dateFormatter($0)
                }
            let allFormatters = formatters.recursivelyMerged(
                with: pipelineFormatters
            )

            let filter = ContentFilter(
                filterRules: pipeline.contentTypes.filterRules
            )

            let filteredContents = filter.applyRules(
                contents: sourceBundle.contents,
                now: now
            )

            let contents = iteratorResolver.resolve(
                contents: filteredContents,
                using: pipeline
            )

            let assetResults = try executor.execute(
                pipeline: pipeline,
                contents: contents
            )
            results.append(contentsOf: assetResults)

            let assetPropertyResolver = AssetPropertyResolver(
                contentsUrl: sourceBundle.sourceConfig.contentsUrl,
                assetsPath: sourceBundle.sourceConfig.config.contents.assets
                    .path,
                baseUrl: sourceBundle.baseUrl,
                config: pipeline.assets
            )

            let finalContents = try assetPropertyResolver.resolve(contents)

            let lastUpdate =
                getLastContentUpdate(
                    contents: contents,
                    pipeline: pipeline,
                    now: now
                ) ?? now

            let lastUpdateContext = lastUpdate.toDateFormats(
                formatters: allFormatters
            )
            siteContext["lastUpdate"] = .init(lastUpdateContext)

            let contextBundles = try getContextBundles(
                contents: finalContents,
                context: [
                    "site": .init(siteContext)
                ],
                pipeline: pipeline,
                now: now
            )

            switch pipeline.engine.id {
            case "json", "context":
                let renderer = ContextBundleToJSONRenderer(
                    pipeline: pipeline,
                    logger: logger
                )
                results += renderer.render(contextBundles)

            case "mustache":
                let renderer = try ContextBundleToHTMLRenderer(
                    pipeline: pipeline,
                    templates: sourceBundle.templates,
                    logger: logger
                )
                results += renderer.render(contextBundles)
            default:
                logger.error(
                    "Unknown renderer engine `\(pipeline.engine.id)`"
                )
            }
        }
        return results
    }

    /// Returns the renderable context bundle for each content for a given pipeline using the global context
    mutating func getContextBundles(
        contents: [Content],
        context globalContext: [String: AnyCodable],
        pipeline: Pipeline,
        now: TimeInterval
    ) throws -> [ContextBundle] {
        contents.compactMap { content in
            let isAllowed = pipeline.contentTypes.isAllowed(
                contentType: content.definition.id
            )
            guard isAllowed else {
                return nil
            }

            let pipelineContext = getPipelineContext(
                contents: contents,
                pipeline: pipeline,
                currentSlug: content.slug.value,
                now: now
            )
            .recursivelyMerged(with: globalContext)

            return getContextBundle(
                contents: contents,
                content: content,
                pipeline: pipeline,
                pipelineContext: pipelineContext,
                now: now
            )
        }
    }

    mutating func getPipelineContext(
        contents: [Content],
        pipeline: Pipeline,
        currentSlug: String,
        now: TimeInterval
    ) -> [String: AnyCodable] {
        var rawContext: [String: AnyCodable] = [:]
        for (key, query) in pipeline.queries {
            let results = contents.run(query: query, now: now)

            rawContext[key] = .init(
                results.map {
                    getContentContext(
                        contents: contents,
                        for: $0,
                        pipeline: pipeline,
                        now: now,
                        scopeKey: query.scope ?? "list",
                        currentSlug: currentSlug
                    )
                }
            )
        }
        return [
            "context": .init(rawContext)
        ]
    }

    mutating func getIteratorContext(
        contents: [Content],
        content: Content,
        pipeline: Pipeline,
        now: TimeInterval
    ) -> [String: AnyCodable] {
        guard let iteratorInfo = content.iteratorInfo else {
            return [:]
        }
        let itemContext = iteratorInfo.items.map {
            getContentContext(
                contents: contents,
                for: $0,
                pipeline: pipeline,
                now: now,
                scopeKey: iteratorInfo.scope ?? "list",
                currentSlug: content.slug.value
            )
        }
        return [
            "iterator": .init(
                [
                    "total": .init(iteratorInfo.total),
                    "limit": .init(iteratorInfo.limit),
                    "current": .init(iteratorInfo.current),
                    "items": .init(itemContext),
                    "links": .init(iteratorInfo.links),
                ] as [String: AnyCodable]
            )
        ]
    }

    mutating func getContextBundle(
        contents: [Content],
        content: Content,
        pipeline: Pipeline,
        pipelineContext: [String: AnyCodable],
        now: TimeInterval
    ) -> ContextBundle {

        let pageContext = getContentContext(
            contents: contents,
            for: content,
            pipeline: pipeline,
            now: now,
            scopeKey: "detail",
            currentSlug: content.slug.value
        )

        let iteratorContext = getIteratorContext(
            contents: contents,
            content: content,
            pipeline: pipeline,
            now: now
        )

        let context: [String: AnyCodable] = [
            "page": .init(pageContext)
        ]
        .recursivelyMerged(with: iteratorContext)
        .recursivelyMerged(with: pipelineContext)

        var outputArgs: [String: String] = [
            "{{id}}": content.id,
            "{{slug}}": content.slug.value,
        ]

        if let info = content.iteratorInfo {
            outputArgs["{{iterator.current}}"] = String(info.current)
            outputArgs["{{iterator.total}}"] = String(info.total)
            outputArgs["{{iterator.limit}}"] = String(info.limit)
        }

        let path = pipeline.output.path.replacingOccurrences(outputArgs)
        let file = pipeline.output.file.replacingOccurrences(outputArgs)
        let ext = pipeline.output.ext.replacingOccurrences(outputArgs)

        return .init(
            content: content,
            context: context,
            destination: .init(
                path: path,
                file: file,
                ext: ext
            )
        )
    }

    mutating func getContentContext(
        contents: [Content],
        for content: Content,
        pipeline: Pipeline,
        now: TimeInterval,
        scopeKey: String,
        currentSlug: String?,
        allowSubQueries: Bool = true  // allow top level queries only,
    ) -> [String: AnyCodable] {
        var result: [String: AnyCodable] = [:]

        let pipelineFormatters = pipeline.dataTypes.date.dateFormats.mapValues {
            sourceBundle.settings.dateFormatter($0)
        }
        let allFormatters = formatters.recursivelyMerged(
            with: pipelineFormatters
        )

        let scope = pipeline.getScope(
            keyedBy: scopeKey,
            for: content.definition.id
        )

        let cacheKey = [
            pipeline.id,
            content.slug.value,
            //            currentSlug ?? "",  // still a bit slow due to this
            scopeKey,
            String(allowSubQueries),
        ]
        .joined(separator: "_")

        if let cachedContext = contentContextCache[cacheKey] {
            return cachedContext
        }

        if scope.context.contains(.userDefined) {
            result = result.recursivelyMerged(with: content.userDefined)
        }

        if scope.context.contains(.properties) {
            for (k, v) in content.properties {
                if let p = content.definition.properties[k],
                    case .date(_) = p.type,
                    let rawDate = v.value(as: Double.self)
                {
                    result[k] = .init(
                        rawDate.toDateFormats(formatters: allFormatters)
                    )
                }
                else {
                    result[k] = .init(v.value)
                }
            }

            result["slug"] = .init(content.slug)
            result["permalink"] = .init(
                content.slug.permalink(baseUrl: sourceBundle.settings.baseUrl)
            )

            // result["isCurrentURL"] = .init(content.slug == currentSlug)
            result["lastUpdate"] = .init(
                content.rawValue.lastModificationDate.toDateFormats(
                    formatters: allFormatters
                )
            )
        }

        if scope.context.contains(.contents) {
            let renderer = ContentRenderer(
                configuration: .init(
                    markdown: .init(
                        customBlockDirectives: sourceBundle.blockDirectives
                    ),
                    outline: .init(
                        levels: sourceBundle.config.renderer
                            .outlineLevels
                    ),
                    readingTime: .init(
                        wordsPerMinute: sourceBundle.config
                            .renderer.wordsPerMinute
                    ),
                    transformerPipeline: pipeline.transformers[
                        content.definition.id
                    ],
                    paragraphStyles: sourceBundle.config.renderer
                        .paragraphStyles
                ),

                fileManager: fileManager,
                logger: logger
            )

            let contents = renderer.render(
                content: content.rawValue.markdown,
                slug: content.slug,
                assetsPath: sourceBundle.config.contents.assets.path,
                baseUrl: sourceBundle.baseUrl
            )

            result["contents"] = [
                "html": contents.html,
                "readingTime": contents.readingTime,
                "outline": contents.outline,
            ]
        }

        if scope.context.contains(.relations) {
            for (key, relation) in content.definition.relations {
                var orderBy: [Order] = []
                if let order = relation.order {
                    orderBy.append(order)
                }

                let relationContents = contents.run(
                    query: .init(
                        contentType: relation.references,
                        filter: .field(
                            key: "id",
                            operator: .in,
                            value: .init(
                                content.relations[key]?.identifiers ?? []
                            )
                        ),
                        orderBy: orderBy
                    ),
                    now: now
                )
                result[key] = .init(
                    relationContents.map {
                        getContentContext(
                            contents: contents,
                            for: $0,
                            pipeline: pipeline,
                            now: now,
                            scopeKey: "reference",
                            currentSlug: currentSlug,
                            allowSubQueries: false
                        )
                    }
                )
            }
        }

        if allowSubQueries, scope.context.contains(.queries) {

            for (key, query) in content.definition.queries {
                let queryContents = contents.run(
                    query: query.resolveFilterParameters(
                        with: content.queryFields
                    ),
                    now: now
                )

                result[key] = .init(
                    queryContents.map {
                        getContentContext(
                            contents: contents,
                            for: $0,
                            pipeline: pipeline,
                            now: now,
                            scopeKey: query.scope ?? "list",
                            currentSlug: currentSlug,
                            allowSubQueries: false
                        )
                    }
                )
            }
        }

        guard !scope.fields.isEmpty else {
            contentContextCache[cacheKey] = result
            return result
        }
        contentContextCache[cacheKey] = result
        return result.filter { scope.fields.contains($0.key) }
    }
}

extension SourceBundleRenderer {

    static func prepareFormatters(
        _ sourceBundle: SourceBundle
    ) -> [String: DateFormatter] {
        var formatters: [String: DateFormatter] = [:]
        let styles: [(String, DateFormatter.Style)] = [
            ("full", .full),
            ("long", .long),
            ("medium", .medium),
            ("short", .short),
        ]

        for (key, style) in styles {
            let dateFormatter = sourceBundle.settings.dateFormatter()
            dateFormatter.dateStyle = style
            dateFormatter.timeStyle = .none
            formatters["date.\(key)"] = dateFormatter

            let timeFormatter = sourceBundle.settings.dateFormatter()
            timeFormatter.dateStyle = .none
            timeFormatter.timeStyle = style
            formatters["time.\(key)"] = timeFormatter
        }

        let standard: [String: LocalizedDateFormat] = [
            "iso8601": .init(format: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"),
            "rss": .init(format: "EEE, dd MMM yyyy HH:mm:ss Z"),
            "sitemap": .init(format: "yyyy-MM-dd"),
        ]

        for (key, dateFormat) in standard.recursivelyMerged(
            with: sourceBundle.config.dateFormats.output
        ) {
            let formatter = sourceBundle.settings.dateFormatter()
            formatter.config(with: dateFormat)
            formatters[key] = formatter
        }
        return formatters
    }
}
