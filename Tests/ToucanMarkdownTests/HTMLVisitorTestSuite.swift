//
//  HTMLVisitorTestSuite.swift
//  Toucan
//
//  Created by Binary Birds on 2025. 04. 15..

import Logging
import Markdown
import Testing

@testable import ToucanMarkdown

@Suite
struct HTMLVisitorTestSuite {
    func renderHTML(
        markdown: String,
        baseURL: String? = nil
    ) -> String {
        let document = Document(
            parsing: markdown,
            options: []
        )

        var visitor = HTMLVisitor(
            blockDirectives: [],
            paragraphStyles: [
                "note": ["note"],
                "warning": ["warn", "warning"],
                "tip": ["tip"],
                "important": ["important"],
                "error": ["error", "caution"],
            ],
            slug: "slug",
            assetsPath: "assets",
            baseURL: baseURL ?? "http://localhost:3000"
        )

        return visitor.visit(document)
    }

    // MARK: - standard elements

    @Test
    func inlineHTML() {
        let input = #"""
            <b>https://swift.org</b>
            """#
        let output = renderHTML(markdown: input)

        let expectation = #"""
            <p><b>https://swift.org</b></p>
            """#

        #expect(output == expectation)
    }

    @Test
    func paragraph() {
        let input = #"""
            Lorem ipsum dolor sit amet.
            """#
        let output = renderHTML(markdown: input)

        let expectation = #"""
            <p>Lorem ipsum dolor sit amet.</p>
            """#

        #expect(output == expectation)
    }

    @Test
    func softBreak() {
        let input = #"""
            This is the first line.
            And this is the second line.
            """#
        let output = renderHTML(markdown: input)

        let expectation = #"""
            <p>This is the first line.<br>And this is the second line.</p>
            """#

        #expect(output == expectation)
    }

    @Test
    func lineBreak() {
        let input = #"""
            a\
            b
            """#
        let output = renderHTML(markdown: input)

        let expectation = #"""
            <p>a<br>b</p>
            """#

        #expect(output == expectation)
    }

    @Test
    func thematicBreak() {
        let input = #"""
            Lorem ipsum
            ***
            dolor
            ---
            sit
            _________________
            amet.
            """#
        let output = renderHTML(markdown: input)

        let expectation = #"""
            <p>Lorem ipsum</p><hr><h2 id="dolor">dolor</h2><p>sit</p><hr><p>amet.</p>
            """#

        #expect(output == expectation)
    }

    @Test
    func strong() {
        let input = #"""
            Lorem **ipsum** dolor __sit__ amet.
            """#
        let output = renderHTML(markdown: input)

        let expectation = #"""
            <p>Lorem <strong>ipsum</strong> dolor <strong>sit</strong> amet.</p>
            """#

        #expect(output == expectation)
    }

    @Test
    func striketrough() {
        let input = #"""
            Lorem ipsum ~~dolor sit amet~~.
            """#
        let output = renderHTML(markdown: input)

        let expectation = #"""
            <p>Lorem ipsum <s>dolor sit amet</s>.</p>
            """#

        #expect(output == expectation)
    }

    @Test
    func blockquote() {
        let input = #"""
            > Lorem ipsum dolor sit amet.
            """#
        let output = renderHTML(markdown: input)

        let expectation = #"""
            <blockquote><p>Lorem ipsum dolor sit amet.</p></blockquote>
            """#

        #expect(output == expectation)
    }

    @Test
    func blockquoteNote() {
        let input = #"""
            > NOTE: Lorem ipsum dolor sit amet.
            """#
        let output = renderHTML(markdown: input)

        let expectation = #"""
            <blockquote class="note"><p>Lorem ipsum dolor sit amet.</p></blockquote>
            """#

        #expect(output == expectation)
    }

    @Test
    func blockquoteWarn() {
        let input = #"""
            > WARN: Lorem ipsum dolor sit amet.
            """#
        let output = renderHTML(markdown: input)
        let expectation = #"""
            <blockquote class="warning"><p>Lorem ipsum dolor sit amet.</p></blockquote>
            """#

        #expect(output == expectation)
    }

    @Test
    func blockquoteWarning() {
        let input = #"""
            > warning: Lorem ipsum dolor sit amet.
            """#
        let output = renderHTML(markdown: input)
        let expectation = #"""
            <blockquote class="warning"><p>Lorem ipsum dolor sit amet.</p></blockquote>
            """#

        #expect(output == expectation)
    }

    @Test
    func nestedBlockquote() {
        let input = #"""
            > Lorem ipsum
            >
            >> dolor __sit__ amet.
            """#
        let output = renderHTML(markdown: input)
        let expectation = #"""
            <blockquote><p>Lorem ipsum</p><blockquote><p>dolor <strong>sit</strong> amet.</p></blockquote></blockquote>
            """#

        #expect(output == expectation)
    }

    @Test
    func emphasis() {
        let input = #"""
            Lorem *ipsum* dolor _sit_ amet.
            """#
        let output = renderHTML(markdown: input)
        let expectation = #"""
            <p>Lorem <em>ipsum</em> dolor <em>sit</em> amet.</p>
            """#

        #expect(output == expectation)
    }

    // MARK: - headings

    @Test
    func h1() {
        let input = #"""
            # Lorem ipsum dolor sit amet.
            """#
        let output = renderHTML(markdown: input)
        let expectation = #"""
            <h1>Lorem ipsum dolor sit amet.</h1>
            """#

        #expect(output == expectation)
    }

    @Test
    func h2() {
        let input = #"""
            ## Lorem ipsum dolor sit amet.
            """#
        let output = renderHTML(markdown: input)
        let expectation = #"""
            <h2 id="lorem-ipsum-dolor-sit-amet.">Lorem ipsum dolor sit amet.</h2>
            """#

        #expect(output == expectation)
    }

    @Test
    func h3() {
        let input = #"""
            ### Lorem ipsum dolor sit amet.
            """#
        let output = renderHTML(markdown: input)
        let expectation = #"""
            <h3 id="lorem-ipsum-dolor-sit-amet.">Lorem ipsum dolor sit amet.</h3>
            """#

        #expect(output == expectation)
    }

    @Test
    func h4() {
        let input = #"""
            #### Lorem ipsum dolor sit amet.
            """#
        let output = renderHTML(markdown: input)
        let expectation = #"""
            <h4>Lorem ipsum dolor sit amet.</h4>
            """#

        #expect(output == expectation)
    }

    @Test
    func h5() {
        let input = #"""
            ##### Lorem ipsum dolor sit amet.
            """#
        let output = renderHTML(markdown: input)
        let expectation = #"""
            <h5>Lorem ipsum dolor sit amet.</h5>
            """#

        #expect(output == expectation)
    }

    @Test
    func h6() {
        let input = #"""
            ###### Lorem ipsum dolor sit amet.
            """#
        let output = renderHTML(markdown: input)
        let expectation = #"""
            <h6>Lorem ipsum dolor sit amet.</h6>
            """#

        #expect(output == expectation)
    }

    @Test
    func invalidHeading() {
        /// NOTE: this should be treated as a paragraph
        let input = #"""
            ####### Lorem ipsum dolor sit amet.
            """#
        let output = renderHTML(markdown: input)
        let expectation = #"""
            <p>####### Lorem ipsum dolor sit amet.</p>
            """#

        #expect(output == expectation)
    }

    // MARK: - lists

    @Test
    func unorderedList() {
        let input = #"""
            - foo
            - bar
            - baz
            """#
        let output = renderHTML(markdown: input)
        let expectation = #"""
            <ul><li>foo</li><li>bar</li><li>baz</li></ul>
            """#

        #expect(output == expectation)
    }

    @Test
    func orderedList() {
        let input = #"""
            1. foo
            2. bar
            3. baz
            """#
        let output = renderHTML(markdown: input)
        let expectation = #"""
            <ol><li>foo</li><li>bar</li><li>baz</li></ol>
            """#

        #expect(output == expectation)
    }

    @Test
    func orderedListWithStartIndex() {
        let input = #"""
            2. foo
            3. bar
            4. baz
            """#
        let output = renderHTML(markdown: input)
        let expectation = #"""
            <ol start="2"><li>foo</li><li>bar</li><li>baz</li></ol>
            """#

        #expect(output == expectation)
    }

    @Test
    func listWithCode() {
        let input = #"""
            - foo `aaa`
            - bar
            - baz
            """#
        let output = renderHTML(markdown: input)
        let expectation = #"""
            <ul><li>foo <code>aaa</code></li><li>bar</li><li>baz</li></ul>
            """#

        #expect(output == expectation)
    }

    // MARK: - other elements

    @Test
    func inlineCode() {
        let input = #"""
            Lorem `ipsum dolor` sit amet.
            """#
        let output = renderHTML(markdown: input)
        let expectation = #"""
            <p>Lorem <code>ipsum dolor</code> sit amet.</p>
            """#

        #expect(output == expectation)
    }

    @Test
    func link() {
        let input = #"""
            [Swift](https://swift.org/)
            """#
        let output = renderHTML(markdown: input)
        let expectation = #"""
            <p><a href="https://swift.org/" target="_blank">Swift</a></p>
            """#

        #expect(output == expectation)
    }

    @Test
    func emptyLink() {
        let input = #"""
            [Swift]()
            """#
        let output = renderHTML(markdown: input)
        let expectation = #"""
            <p><a>Swift</a></p>
            """#

        #expect(output == expectation)
    }

    @Test
    func dotLink() {
        let input = #"""
            [Swift](./foo)
            """#
        let output = renderHTML(markdown: input)
        let expectation = #"""
            <p><a href="./foo">Swift</a></p>
            """#

        #expect(output == expectation)
    }

    @Test
    func slashLink() {
        let input = #"""
            [Swift](/foo)
            """#
        let output = renderHTML(markdown: input)
        let expectation = #"""
            <p><a href="http://localhost:3000/foo">Swift</a></p>
            """#

        #expect(output == expectation)
    }

    @Test
    func externalLink() {
        let input = #"""
            [Swift](foo/bar)
            """#
        let output = renderHTML(markdown: input)
        let expectation = #"""
            <p><a href="foo/bar" target="_blank">Swift</a></p>
            """#

        #expect(output == expectation)
    }

    @Test
    func anchorLink() {
        let input = #"""
            [Swift](#anchor)
            """#
        let output = renderHTML(markdown: input)
        let expectation = #"""
            <p><a href="#anchor">Swift</a></p>
            """#

        #expect(output == expectation)
    }

    @Test
    func anchorName() {
        let input = #"""
            [Swift](#[name]anchor)
            """#
        let output = renderHTML(markdown: input)
        let expectation = #"""
            <p><a name="anchor">Swift</a></p>
            """#

        #expect(output == expectation)
    }

    @Test
    func image() {
        let input = #"""
            ![Lorem](lorem.jpg)
            """#
        let output = renderHTML(markdown: input)
        let expectation = #"""
            <p><img src="lorem.jpg" alt="Lorem"></p>
            """#

        #expect(output == expectation)
    }

    @Test
    func imageAssetsPrefix() {
        let input = #"""
            ![Lorem](./assets/lorem.jpg)
            """#
        let output = renderHTML(markdown: input)
        let expectation = #"""
            <p><img src="http://localhost:3000/assets/slug/lorem.jpg" alt="Lorem"></p>
            """#
        #expect(output == expectation)
    }

    @Test
    func imageEmptySource() {
        let input = #"""
            ![Lorem]()
            """#
        let output = renderHTML(markdown: input)
        let expectation = #"""
            <p></p>
            """#

        #expect(output == expectation)
    }

    @Test
    func imageWithTitle() {
        let input = #"""
            ![Lorem](lorem.jpg "Image title")
            """#
        let output = renderHTML(markdown: input)
        let expectation = #"""
            <p><img src="lorem.jpg" alt="Lorem" title="Image title"></p>
            """#

        #expect(output == expectation)
    }

    @Test
    func imageWithEmptyBaseURL() {
        let input = #"""
            ![Lorem](/lorem.jpg "Image title")
            """#
        let output = renderHTML(markdown: input, baseURL: "")
        let expectation = #"""
            <p><img src="/lorem.jpg" alt="Lorem" title="Image title"></p>
            """#

        #expect(output == expectation)
    }

    @Test
    func imageWithBaseURLMarkdownValue() {
        let input = #"""
            ![Lorem](/lorem.jpg)
            """#
        let output = renderHTML(markdown: input)
        let expectation = #"""
            <p><img src="http://localhost:3000/lorem.jpg" alt="Lorem"></p>
            """#

        #expect(output == expectation)
    }

    @Test
    func imageWithBaseURLMarkdownValueNoTraling() {
        let input = #"""
            ![Lorem](/lorem.jpg)
            """#
        let output = renderHTML(markdown: input)
        let expectation = #"""
            <p><img src="http://localhost:3000/lorem.jpg" alt="Lorem"></p>
            """#

        #expect(output == expectation)
    }

    @Test
    func codeBlock() {
        let input = #"""
            ```js
            Lorem
            ipsum
            dolor
            sit
            amet
            ```
            """#
        let output = renderHTML(markdown: input)
        let expectation = #"""
            <pre><code class="language-js">Lorem
            ipsum
            dolor
            sit
            amet
            </code></pre>
            """#

        #expect(output == expectation)
    }

    @Test
    func codeBlockWithHighlight() {
        let input = #"""
            ```css
            Lorem
            /*!*/
                ipsum
            /*.*/
            dolor
            sit
            amet
            ```
            """#
        let output = renderHTML(markdown: input)
        let expectation = #"""
            <pre><code class="language-css">Lorem
            <span class="highlight">
                ipsum
            </span>
            dolor
            sit
            amet
            </code></pre>
            """#

        #expect(output == expectation)
    }

    @Test
    func codeBlockWithHighlightSwift() {
        let input = #"""
            ```swift
            /*!*/func main() -> String/*.*/ {
                dump("Hello world")
                return /*!*/"foo"/*.*/
            }
            ```
            """#
        let output = renderHTML(markdown: input)
        let expectation = #"""
            <pre><code class="language-swift"><span class="highlight">func main() -&gt; String</span> {
                dump("Hello world")
                return <span class="highlight">"foo"</span>
            }
            </code></pre>
            """#

        #expect(output == expectation)
    }

    @Test
    func table() {
        let input = #"""
            | Item              | In Stock | Price |
            | :---------------- | :------: | ----: |
            | Python Hat        |   True   | 23.99 |
            | SQL Hat           |   True   | 23.99 |
            | Codecademy Tee    |  False   | 19.99 |
            | Codecademy Hoodie |  False   | 42.99 |
            """#
        let output = renderHTML(markdown: input)
        let expectation = #"""
            <table><thead><td>Item</td><td>In Stock</td><td>Price</td></thead><tbody><tr><td>Python Hat</td><td>True</td><td>23.99</td></tr><tr><td>SQL Hat</td><td>True</td><td>23.99</td></tr><tr><td>Codecademy Tee</td><td>False</td><td>19.99</td></tr><tr><td>Codecademy Hoodie</td><td>False</td><td>42.99</td></tr></tbody></table>
            """#

        #expect(output == expectation)
    }

    @Test
    func headingWithAngleBracket() {
        let input = #"""
            ## This <is a> bracket
            """#
        let output = renderHTML(markdown: input)
        let expectation = #"""
            <h2 id="this-is-a-bracket">This &lt;is a&gt; bracket</h2>
            """#

        #expect(output == expectation)
    }

    @Test
    func codeWithAngleBracket() {
        let input = #"""
            See the `<head>` tag.
            """#
        let output = renderHTML(markdown: input)
        let expectation = #"""
            <p>See the <code>&lt;head&gt;</code> tag.</p>
            """#

        #expect(output == expectation)
    }
}
