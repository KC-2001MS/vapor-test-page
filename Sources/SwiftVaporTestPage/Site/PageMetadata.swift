/// `<head>` に出力するメタデータ（タイトル・説明・OGP・Twitterカードなど）
struct PageMetadata: Encodable, Sendable {
    enum TwitterCard: String, Encodable, Sendable {
        case summary
        case summaryLargeImage = "summary_large_image"
    }

    var title: String
    var description: String
    var keywords: [String]
    /// 言語の接頭辞（`/en`）を含まないパス。例：`/product/atpnexus`
    var path: String
    var siteName: String
    var twitterCard: TwitterCard = .summary
    var indexable: Bool = true
    /// App Storeのアプリ（Smart App Banner）
    var appID: String? = nil

    // 以下はテンプレートで使うための値（`resolved(for:)` で埋める）
    var applicationName = ""
    var author = ""
    var keywordList = ""
    var canonicalURL = ""
    var japaneseURL = ""
    var englishURL = ""
    var imageURL = ""

    init(title: String, description: String, keywords: [String], path: String, siteName: String, twitterCard: TwitterCard = .summary, indexable: Bool = true, appID: String? = nil) {
        self.title = title
        self.description = description
        self.keywords = keywords
        self.path = path
        self.siteName = siteName
        self.twitterCard = twitterCard
        self.indexable = indexable
        self.appID = appID
    }

    /// 言語ごとのURLなどを埋めたメタデータ
    func resolved(for language: SiteLanguage, siteURL: String) -> PageMetadata {
        var metadata = self
        let suffix = path == "/" ? "/" : path
        metadata.applicationName = language.strings.siteTitle
        metadata.author = Self.author(language)
        metadata.keywordList = keywords.joined(separator: ",")
        metadata.japaneseURL = siteURL + suffix
        metadata.englishURL = siteURL + "/en" + suffix
        metadata.canonicalURL = language == .english ? metadata.englishURL : metadata.japaneseURL
        metadata.imageURL = siteURL + "/images/出雲大社1080.jpg"
        return metadata
    }

    static func author(_ language: SiteLanguage) -> String {
        language == .english ? "Keisuke Chinone" : "茅根啓介"
    }
}

// MARK: - 固定ページのメタデータ

extension PageMetadata {
    private static func defaultKeywords(_ language: SiteLanguage) -> [String] {
        language == .english ? ["SwiftUI", "Keisuke", "Chinone"] : ["SwiftUI", "茅根啓介"]
    }

    private static func listSiteName(_ language: SiteLanguage) -> String {
        language == .english ? "Iroiro's portfolio" : "いろいろのポートフォリオ"
    }

    static func home(_ language: SiteLanguage) -> PageMetadata {
        switch language {
        case .japanese:
            PageMetadata(
                title: "【SwiftUIアプリ開発】いろいろポートフォリオ",
                description: "茅根啓介（活動名：いろいろ）のポートフォリオサイトです。Appleプラットフォームでアプリケーションを展開しております。このサイトでは、App Storeでリリースしたアプリの情報とサポート等を行います。",
                keywords: defaultKeywords(language), path: "/", siteName: listSiteName(language), twitterCard: .summaryLargeImage
            )
        case .english:
            PageMetadata(
                title: "Iroiro's portfolio【SwiftUI】",
                description: "Keisuke Chinone's (activity name: Iroiro) portfolio site, I'm developing applications on Apple platforms. This site provides information and support for applications released on the App Store.",
                keywords: defaultKeywords(language), path: "/", siteName: listSiteName(language), twitterCard: .summaryLargeImage
            )
        }
    }

    static func notFound(_ language: SiteLanguage) -> PageMetadata {
        switch language {
        case .japanese:
            PageMetadata(
                title: "このページは存在しない",
                description: "いろいろポートフォリオにこのページは存在しない",
                keywords: ["404", "存在", "茅根啓介"], path: "/404", siteName: listSiteName(language), indexable: false
            )
        case .english:
            PageMetadata(
                title: "This page does not exist.",
                description: "This page does not exist in the Iroiro's portfolios.",
                keywords: ["404", "existence", "Keisuke", "Chinone"], path: "/404", siteName: listSiteName(language), indexable: false
            )
        }
    }

    static func contact(_ language: SiteLanguage) -> PageMetadata {
        switch language {
        case .japanese:
            PageMetadata(
                title: "いろいろへのお問い合わせ",
                description: "茅根啓介（活動名：いろいろ）の展開したアプリやプロジェクト・サービスについてのお問い合わせ先です。",
                keywords: defaultKeywords(language), path: "/contact", siteName: listSiteName(language), twitterCard: .summaryLargeImage
            )
        case .english:
            PageMetadata(
                title: "Contact Iroiro",
                description: "Contact information for inquiries about applications, projects and services developed by Keisuke Chinone (activity name: Iroiro).",
                keywords: defaultKeywords(language), path: "/contact", siteName: listSiteName(language), twitterCard: .summaryLargeImage
            )
        }
    }

    static func product(_ language: SiteLanguage) -> PageMetadata {
        switch language {
        case .japanese:
            PageMetadata(
                title: "いろいろが開発したアプリや貢献したプロジェクト・サービス",
                description: "茅根啓介（活動名：いろいろ）の展開したアプリやプロジェクト・サービスです。それぞれのサービスの概要について詳しく説明します。",
                keywords: defaultKeywords(language), path: "/product", siteName: listSiteName(language)
            )
        case .english:
            PageMetadata(
                title: "Applications developed and projects/services contributed to by the Iroiro",
                description: "These are the applications, projects and services developed by Keisuke Chinone (activity name: Iroiro). An overview of each service will be described in detail.",
                keywords: defaultKeywords(language), path: "/product", siteName: listSiteName(language)
            )
        }
    }

    static func privacy(_ language: SiteLanguage) -> PageMetadata {
        switch language {
        case .japanese:
            PageMetadata(
                title: "プライバシーポリシー",
                description: "茅根啓介（活動名：いろいろ）の展開する全てのサービスに関するプライバシーポリシーです。",
                keywords: ["プライバシーポリシー", "茅根啓介"], path: "/privacy", siteName: listSiteName(language)
            )
        case .english:
            PageMetadata(
                title: "Privacy Policy",
                description: "This is the privacy policy for all services developed by Keisuke Chinone (activity name: Iroiro).",
                keywords: ["Privacy", "Policy", "Keisuke", "Chinone"], path: "/privacy", siteName: listSiteName(language)
            )
        }
    }

    static func agreement(_ language: SiteLanguage) -> PageMetadata {
        switch language {
        case .japanese:
            PageMetadata(
                title: "利用規約",
                description: "茅根啓介（活動名：いろいろ）の展開する全てのサービスに関する利用規約です。",
                keywords: ["利用規約", "茅根啓介"], path: "/agreement", siteName: listSiteName(language)
            )
        case .english:
            PageMetadata(
                title: "Terms of Use",
                description: "This is the Terms of Use for all services developed by Keisuke Chinone (activity name: Iroiro).",
                keywords: ["Agreement", "Keisuke", "Chinone"], path: "/agreement", siteName: listSiteName(language)
            )
        }
    }

    static func articleList(_ section: ArticleSection, _ language: SiteLanguage) -> PageMetadata {
        let defaults = section.defaults(language)
        return PageMetadata(
            title: defaults.title, description: defaults.description,
            keywords: defaultKeywords(language), path: "/" + section.path, siteName: listSiteName(language), twitterCard: .summaryLargeImage
        )
    }

    /// Markdownの記事のメタデータ（フロントマターがなければ既定の文言）
    static func article(_ article: Article, in section: ArticleSection, _ language: SiteLanguage) -> PageMetadata {
        let defaults = section.defaults(language)
        return PageMetadata(
            title: article.frontMatter.title ?? defaults.title,
            description: article.frontMatter.description ?? defaults.description,
            keywords: article.frontMatter.keywords,
            path: "/\(section.path)/\(article.slug)",
            siteName: language.strings.siteTitle,
            appID: article.frontMatter.appID
        )
    }
}
