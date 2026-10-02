/// サイトの表示言語
/// 日本語はルート（`/`）、英語は `/en` 以下に置く
enum SiteLanguage: String, CaseIterable, Sendable {
    case japanese = "ja"
    case english = "en"

    /// URLの先頭に付けるパス（日本語は空）
    var pathPrefix: String {
        switch self {
        case .japanese: ""
        case .english: "/en"
        }
    }

    /// `Content/` 内のディレクトリ名
    var contentDirectory: String { rawValue }

    /// App Storeの価格を取得するときの国
    var appStoreCountry: String {
        switch self {
        case .japanese: "jp"
        case .english: "us"
        }
    }

    /// パスの先頭から言語を判定する（`/en` または `/en/...` なら英語）
    init(path: String) {
        self = path == "/en" || path.hasPrefix("/en/") ? .english : .japanese
    }

    var strings: SiteStrings {
        switch self {
        case .japanese: .japanese
        case .english: .english
        }
    }
}
