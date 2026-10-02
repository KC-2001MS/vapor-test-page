import Foundation

/// すべてのページに共通する値（レイアウト・ヘッダー・フッター・`<head>`）
struct LayoutContext: Encodable, Sendable {
    /// `ja` または `en`
    var lang: String
    /// `<meta name="language">` の値
    var languageName: String
    /// サイトの公開パス（画像・CSSなどのURLの先頭）
    var base: String
    /// 言語の接頭辞まで含めたパス（ページへのリンクの先頭）
    var home: String
    /// もう一方の言語のトップページ
    var otherLanguageHome: String
    var t: SiteStrings
    var meta: PageMetadata
    var analyticsID: String?
    /// `<meta name="date">`（ページを作った日）
    var date: String
    /// X（Twitter）・Blueskyの埋め込み用スクリプトを読み込むか
    var loadsTwitter = false
    var loadsBluesky = false

    init(language: SiteLanguage, metadata: PageMetadata, configuration: SiteConfiguration, date: Date = Date()) {
        let base = configuration.basePath
        self.lang = language.rawValue
        self.languageName = language == .english ? "English" : "Japanese"
        self.base = base
        self.home = base + language.pathPrefix
        self.otherLanguageHome = base + (language == .english ? "/" : "/en/")
        self.t = language.strings
        self.meta = metadata.resolved(for: language, siteURL: SiteConfiguration.siteURL)
        self.analyticsID = configuration.analyticsID

        let components = Calendar(identifier: .gregorian).dateComponents(in: TimeZone(identifier: "Asia/Tokyo")!, from: date)
        self.date = "\(components.year!)-\(components.month!)-\(components.day!)"
    }
}

/// テンプレートに渡す値（共通の値 `site` とページごとの値 `page`）
struct PageContext<Page: Encodable & Sendable>: Encodable, Sendable {
    var site: LayoutContext
    var page: Page
}

struct EmptyPage: Encodable, Sendable {}

/// Markdownのページ
struct ArticlePage: Encodable, Sendable {
    var html: String
    var showsDonation: Bool
}

/// ブログ・ニュースルームの一覧
struct ArticleListPage: Encodable, Sendable {
    struct Item: Encodable, Sendable {
        var title: String
        var description: String
        var genre: String
        var date: String
        var url: String
    }

    var heading: String
    var emptyMessage: String
    var items: [Item]
}

/// コンテンツ（製品一覧）
struct ProductPage: Encodable, Sendable {
    struct AppCard: Encodable, Sendable {
        var title: String
        var appStoreURL: String
        var iconURL: String?
        var darkIconURL: String?
        var iconAlt: String
        var platforms: [String]
        /// 説明（HTML。翻訳のアプリはアプリ名を太字にするため）
        var descriptionHTML: String
        var supportPage: String
        var feedback: String
        var price: String
        var commercials: [ProductCatalog.Commercial]
        var media: [ProductCatalog.Link]
        var originalSource: ProductCatalog.OriginalSource?
        /// 英語版の翻訳アプリに添える問い合わせの案内
        var englishContactNote: String?
    }

    struct Other: Encodable, Sendable {
        var title: String
        var label: String
        var description: String
        var isTemplate: Bool
        var repositoryUrl: String?
        var downloadUrl: String?
        var moreInfoUrl: String?
    }

    /// 開発・移植・翻訳のアプリ
    struct AppSection: Encodable, Sendable {
        var heading: String
        var apps: [AppCard]
        /// 2つ目以降の区切り（`clear` クラス）
        var isFollowing: Bool
    }

    var appSections: [AppSection]
    var others: [Other]
    var frameworks: [ProductCatalog.Project]
    var shellScripts: [ProductCatalog.Project]
    var websites: [ProductCatalog.Project]
    /// 番号付きの商標の注記（`1.〜`）
    var trademarkNotices: [String]
    var appStoreBadgeLight: String
    var appStoreBadgeDark: String
}
