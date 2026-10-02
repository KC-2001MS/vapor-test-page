import Foundation
import Vapor

/// `Content/` から読み込んだサイトの内容（起動時に一度だけ読み込む）
struct SiteContent: Sendable {
    struct LanguageContent: Sendable {
        var catalog: ProductCatalog
        /// 記事の種類ごとの記事（ファイル名順）
        var articles: [ArticleSection: [Article]]
        /// 問い合わせページのMarkdown
        var contact: Article

        func articles(in section: ArticleSection) -> [Article] {
            articles[section] ?? []
        }

        func article(_ slug: String, in section: ArticleSection) -> Article? {
            articles(in: section).first { $0.slug == slug }
        }
    }

    var languages: [SiteLanguage: LanguageContent]

    subscript(language: SiteLanguage) -> LanguageContent {
        // init(directory:) ですべての言語を読み込んでいるため、必ず存在する
        languages[language]!
    }

    init(directory: String) throws {
        var languages: [SiteLanguage: LanguageContent] = [:]
        for language in SiteLanguage.allCases {
            let base = URL(fileURLWithPath: directory).appendingPathComponent(language.contentDirectory)

            let catalogData = try Data(contentsOf: base.appendingPathComponent("product.json"))
            let catalog = try JSONDecoder().decode(ProductCatalog.self, from: catalogData)

            var articles: [ArticleSection: [Article]] = [:]
            for section in ArticleSection.allCases {
                articles[section] = try Self.loadArticles(in: base.appendingPathComponent(section.directory))
            }

            let contactSource = try String(contentsOf: base.appendingPathComponent("contact.md"), encoding: .utf8)
            let contact = Article(slug: "contact", source: contactSource)

            languages[language] = LanguageContent(catalog: catalog, articles: articles, contact: contact)
        }
        self.languages = languages
    }

    /// ディレクトリ内のMarkdownをファイル名順に読み込む（ディレクトリがなければ空）
    private static func loadArticles(in directory: URL) throws -> [Article] {
        guard let filenames = try? FileManager.default.contentsOfDirectory(atPath: directory.path) else {
            return []
        }
        return try filenames
            .filter { $0.hasSuffix(".md") }
            .sorted()
            .map { filename in
                let source = try String(contentsOf: directory.appendingPathComponent(filename), encoding: .utf8)
                return Article(slug: String(filename.dropLast(3)), source: source)
            }
    }
}

extension Application {
    private struct SiteContentKey: StorageKey {
        typealias Value = SiteContent
    }

    /// 読み込んだサイトの内容
    var siteContent: SiteContent {
        get {
            guard let content = storage[SiteContentKey.self] else {
                fatalError("SiteContent is not loaded. Set app.siteContent in configure(_:).")
            }
            return content
        }
        set { storage[SiteContentKey.self] = newValue }
    }
}
