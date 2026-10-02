/// 画面に表示する文言（Leafのテンプレートへ `t` として渡す）
struct SiteStrings: Encodable, Sendable {
    // ヘッダー
    var siteTitle: String
    var home: String
    var contents: String
    var blog: String
    var newsroom: String
    var contact: String

    // トップ・404
    var goalTitle: String
    var goalSubtitleLines: [String]
    var notFoundSubtitleLines: [String]
    var languageLabel: String
    var otherLanguageName: String

    // コンテンツ（製品一覧）
    var applications: String
    var development: String
    var transplanting: String
    var translation: String
    var frameworks: String
    var shellScripts: String
    var websites: String
    var media: String
    var supportedPlatforms: String
    var supportPage: String
    var feedback: String
    var download: String
    var templateLabel: String
    var priceLabel: String
    var priceTaxNote: String
    var appStoreBadgeAlt: String

    // ブログ・ニュースルーム
    var blogHeading: String
    var newsroomHeading: String
    var noBlogPosts: String
    var noNews: String

    // 寄付
    var donationTitle: String
    var donationBody: String

    // コードのコピーボタン
    var copyCode: String
    var copied: String
}

extension SiteStrings {
    static let japanese = SiteStrings(
        siteTitle: "いろいろポートフォリオ",
        home: "ホーム",
        contents: "コンテンツ",
        blog: "ブログ",
        newsroom: "ニュースルーム",
        contact: "問い合わせ",
        goalTitle: "より効率的に。",
        goalSubtitleLines: ["私のほしいものを", "私自身の手で作り出します"],
        notFoundSubtitleLines: ["このページは存在しません。", "このページは作られていないようです。URLが正しいかどうかを確認してください。"],
        languageLabel: "言語",
        otherLanguageName: "English",
        applications: "アプリケーション",
        development: "開発",
        transplanting: "移植",
        translation: "翻訳",
        frameworks: "フレームワーク・パッケージ",
        shellScripts: "シェルスクリプト",
        websites: "ウェブサイト",
        media: "メディア",
        supportedPlatforms: "対応プラットフォーム",
        supportPage: "サポートページ",
        feedback: "フィードバック",
        download: "ダウンロード",
        templateLabel: "テンプレート",
        priceLabel: "価格：",
        priceTaxNote: "（税込）",
        appStoreBadgeAlt: "App Storeからダウンロード",
        blogHeading: "Blog",
        newsroomHeading: "Newsroom",
        noBlogPosts: "現在、ブログ記事はありません。",
        noNews: "現在、ニュースはありません。",
        donationTitle: "寄付",
        donationBody: "寄付をご希望の方は、こちらをクリックしてください。ご寄付いただいたお金は、私のプログラミング・スキルの向上とアプリケーションのメンテナンスに使わせていただきます。",
        copyCode: "コードをコピー",
        copied: "コピーしました"
    )

    static let english = SiteStrings(
        siteTitle: "Iroiro's portfolio",
        home: "Home",
        contents: "Contents",
        blog: "Blog",
        newsroom: "Newsroom",
        contact: "Contact",
        goalTitle: "More efficient.",
        goalSubtitleLines: ["I create what I want", "with my own hands."],
        notFoundSubtitleLines: ["This page does not exist.", "This page does not appear to have been created; please check to see if the URL is correct."],
        languageLabel: "Language",
        otherLanguageName: "日本語",
        applications: "App",
        development: "Development",
        transplanting: "Transplanting",
        translation: "Translation",
        frameworks: "Framework & Packages",
        shellScripts: "Shell Script",
        websites: "Website",
        media: "Media",
        supportedPlatforms: "Supported platforms",
        supportPage: "Support Page",
        feedback: "Feedback",
        download: "Download",
        templateLabel: "Template",
        priceLabel: "Price：",
        priceTaxNote: "",
        appStoreBadgeAlt: "Download on the App Store",
        blogHeading: "Blog",
        newsroomHeading: "Newsroom",
        noBlogPosts: "There are currently no blog posts.",
        noNews: "There is currently no news.",
        donationTitle: "Contribution",
        donationBody: "If you would like to make a donation, please click here. The money you donate will be used to improve my programming skills and maintain the application.",
        copyCode: "Copy code",
        copied: "Copied"
    )
}
