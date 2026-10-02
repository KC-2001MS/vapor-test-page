@testable import VaporTestPage
import VaporTesting
import Testing

@Suite("Site Pages", .serialized)
struct SiteTests {
    private func withApp(_ test: (Application) async throws -> ()) async throws {
        let app = try await Application.make(.testing)
        do {
            try await configure(app)
            try await test(app)
        } catch {
            try await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()
    }

    @Test("Home page in Japanese and English")
    func home() async throws {
        try await withApp { app in
            try await app.testing().test(.GET, "/", afterResponse: { res async in
                #expect(res.status == .ok)
                #expect(res.body.string.contains("<html lang=\"ja\">"))
                #expect(res.body.string.contains("より効率的に。"))
            })
            try await app.testing().test(.GET, "en", afterResponse: { res async in
                #expect(res.status == .ok)
                #expect(res.body.string.contains("<html lang=\"en\">"))
                #expect(res.body.string.contains("More efficient."))
            })
        }
    }

    @Test("Every exported path renders", arguments: [false, true])
    func allPaths(english: Bool) async throws {
        try await withApp { app in
            let paths = SiteController.allPaths(content: app.siteContent).filter { $0.hasPrefix("/en") == english }
            #expect(!paths.isEmpty)
            for path in paths {
                try await app.testing().test(.GET, path, afterResponse: { res async in
                    #expect(res.status == .ok, "\(path)")
                })
            }
        }
    }

    @Test("Product page lists apps from product.json")
    func product() async throws {
        try await withApp { app in
            try await app.testing().test(.GET, "product", afterResponse: { res async in
                #expect(res.status == .ok)
                let body = res.body.string
                #expect(body.contains("<h3 class=\"appName\">ATP Nexus</h3>"))
                #expect(body.contains("ATP%20Nexus%20Light.avif"))
                #expect(body.contains("<span class=\"price\">―</span>"))
                #expect(body.contains("<strong>Declutter for Safari</strong>は"))
            })
        }
    }

    @Test("Markdown article page")
    func article() async throws {
        try await withApp { app in
            try await app.testing().test(.GET, "blog/m5stack-nanoc6-and-embedded-swift", afterResponse: { res async in
                #expect(res.status == .ok)
                let body = res.body.string
                #expect(body.contains("<title>Embedded SwiftでM5Stack NanoC6を動かす</title>"))
                #expect(body.contains("class=\"markdown-image\""))
                #expect(body.contains("class=\"donationTitle\""))
            })
        }
    }

    @Test("Unknown pages show the 404 page")
    func notFound() async throws {
        try await withApp { app in
            try await app.testing().test(.GET, "does-not-exist", afterResponse: { res async in
                #expect(res.status == .notFound)
                #expect(res.body.string.contains("このページは存在しません。"))
            })
            try await app.testing().test(.GET, "en/blog/does-not-exist", afterResponse: { res async in
                #expect(res.status == .notFound)
                #expect(res.body.string.contains("This page does not exist."))
            })
            try await app.testing().test(.GET, "privacy.html", afterResponse: { res async in
                #expect(res.status == .seeOther)
                #expect(res.headers.first(name: .location) == "/privacy")
            })
        }
    }

    @Test("Export file paths")
    func exportFilePaths() {
        #expect(ExportCommand.filePath(for: "/") == "index.html")
        #expect(ExportCommand.filePath(for: "/en/") == "en/index.html")
        #expect(ExportCommand.filePath(for: "/product") == "product.html")
        #expect(ExportCommand.filePath(for: "/en/product/tips/mpsz") == "en/product/tips/mpsz.html")
    }

    @Test("Base path normalization")
    func basePath() {
        #expect(SiteConfiguration.normalize(basePath: "") == "")
        #expect(SiteConfiguration.normalize(basePath: "/") == "")
        #expect(SiteConfiguration.normalize(basePath: "vapor-test-page/") == "/vapor-test-page")
    }
}

@Suite("Markdown")
struct MarkdownTests {
    @Test("Escapes text and code")
    func escaping() {
        let html = MarkdownRenderer().render("a < b & c\n\n```swift\nlet x = \"<tag>\"\n```")
        #expect(html.contains("<p>a &lt; b &amp; c</p>"))
        #expect(html.contains("<pre><code class=\"language-swift\">let x = &quot;&lt;tag&gt;&quot;\n</code></pre>"))
    }

    @Test("Soft line breaks become <br> (remark-breaks)")
    func softBreaks() {
        #expect(MarkdownRenderer().render("line1\nline2") == "<p>line1<br>\nline2</p>\n")
    }

    @Test("Smart quotes are not applied")
    func quotes() {
        #expect(MarkdownRenderer().render("\"Death To _blank\"") == "<p>&quot;Death To _blank&quot;</p>\n")
    }

    @Test("Site-relative links and images get the base path")
    func basePath() {
        let renderer = MarkdownRenderer(basePath: "/site", imageClass: "markdown-image")
        let html = renderer.render("[a](/privacy) [b](https://example.com) ![alt](/images/x.png \"title\")")
        #expect(html.contains("<a href=\"/site/privacy\">a</a>"))
        #expect(html.contains("<a href=\"https://example.com\">b</a>"))
        #expect(html.contains("<img src=\"/site/images/x.png\" alt=\"alt\" title=\"title\" class=\"markdown-image\">"))
    }

    @Test("Tight and loose lists")
    func lists() {
        #expect(MarkdownRenderer().render("- a\n- b") == "<ul>\n<li>a\n</li>\n<li>b\n</li>\n</ul>\n")
        #expect(MarkdownRenderer().render("- a\n\n- b").contains("<li><p>a</p>\n</li>"))
    }

    @Test("Tables")
    func tables() {
        let html = MarkdownRenderer().render("| a | b |\n| --- | :-: |\n| 1 | 2 |")
        #expect(html.contains("<th>a</th>"))
        #expect(html.contains("<td align=\"center\">2</td>"))
    }

    @Test("Raw HTML is kept")
    func rawHTML() {
        let html = MarkdownRenderer().render("<div class=\"donationButtons\">\n<a href=\"x\">y</a>\n</div>")
        #expect(html == "<div class=\"donationButtons\">\n<a href=\"x\">y</a>\n</div>\n")
    }

    @Test("Footnotes (remark-gfm)")
    func footnotes() {
        let html = MarkdownRenderer().render("A[^x] B[^x] C[^2]\n\n[^x]: Note *one*\n[^2]: Note two")
        #expect(html.contains("<sup><a href=\"#user-content-fn-x\" id=\"user-content-fnref-x\" data-footnote-ref=\"\" aria-describedby=\"footnote-label\">1</a></sup>"))
        #expect(html.contains("id=\"user-content-fnref-x-2\""))
        #expect(html.contains(">2</a></sup>"))
        #expect(html.contains("<section data-footnotes=\"\" class=\"footnotes\">"))
        #expect(html.contains("<li id=\"user-content-fn-x\">\n<p>Note <em>one</em> <a href=\"#user-content-fnref-x\""))
        #expect(!html.contains("[^x]"))
    }
}

@Suite("Front matter")
struct FrontMatterTests {
    @Test("Parses strings and arrays")
    func parse() {
        let source = "---\ntitle: \"Hello: world\"\ndescription: plain text\nkeywords: [\"Swift\", \"Vapor\"]\ndate: 2025/9/9\nappId: \"123\"\n---\n# Body"
        let article = Article(slug: "hello", source: source)
        #expect(article.frontMatter.title == "Hello: world")
        #expect(article.frontMatter.description == "plain text")
        #expect(article.frontMatter.keywords == ["Swift", "Vapor"])
        #expect(article.frontMatter.date == "2025/9/9")
        #expect(article.frontMatter.appID == "123")
        #expect(article.body == "# Body")
    }

    @Test("Without front matter")
    func none() {
        let article = Article(slug: "contact", source: "# Contact")
        #expect(article.frontMatter == FrontMatter())
        #expect(article.body == "# Contact")
    }
}
