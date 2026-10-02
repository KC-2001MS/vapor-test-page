import Foundation

/// Markdownで書かれたページの種類
enum ArticleSection: String, CaseIterable, Sendable {
    case product
    case tips
    case blog
    case newsroom

    /// URLのパス（言語の接頭辞を除く）
    var path: String {
        switch self {
        case .product: "product"
        case .tips: "product/tips"
        case .blog: "blog"
        case .newsroom: "newsroom"
        }
    }

    /// `Content/<言語>/` 内のディレクトリ名
    var directory: String { rawValue }

    /// 一覧ページがあるか（ブログ・ニュースルーム）
    var hasListPage: Bool { self == .blog || self == .newsroom }

    /// 記事の末尾に寄付の案内を置くか
    var showsDonation: Bool { self != .product }

    /// X（Twitter）・Blueskyの埋め込み用スクリプトを読み込むか
    var loadsSocialEmbeds: Bool { self == .product }

    /// Markdownの画像に `markdown-image` クラスを付けるか
    var usesMarkdownImageClass: Bool { self == .blog || self == .newsroom }

    /// フロントマターにタイトル・説明がないときの文言
    func defaults(_ language: SiteLanguage) -> (title: String, description: String) {
        switch (self, language) {
        case (.product, .japanese): ("いろいろの製品詳細", "いろいろの製品についての詳細を知ることができるページです。")
        case (.product, .english): ("Iroiro's product details", "This page allows you to learn more about Iroiro's products.")
        case (.tips, .japanese): ("いろいろのTips", "いろいろの製品に関するTipsを知ることができるページです。")
        case (.tips, .english): ("Iroiro's Tips", "This is a page where you can learn about Iroiro's tips about his products.")
        case (.blog, .japanese): ("いろいろのブログ", "いろいろがさまざまな技術についての内容をアウトプットするためのブログです。")
        case (.blog, .english): ("Iroiro's blog", "This is a blog to output various contents about various technologies.")
        case (.newsroom, .japanese): ("ニュースルーム", "いろいろの活動に関わるお知らせです。")
        case (.newsroom, .english): ("Newsroom", "This page allows you to learn more about Iroiro's products.")
        }
    }
}

/// Markdownのページ1件
struct Article: Sendable {
    /// ファイル名から拡張子を除いたもの（URLの末尾になる）
    var slug: String
    var frontMatter: FrontMatter
    /// フロントマターを除いたMarkdown本文
    var body: String

    init(slug: String, source: String) {
        self.slug = slug
        (self.frontMatter, self.body) = FrontMatter.split(source)
    }
}

/// 記事の先頭にある `---` で囲まれたメタデータ
///
/// このサイトのフロントマターは `key: value` の1行形式だけなので、YAMLライブラリは使わずに読み取る。
/// 値は、ダブルクォートの文字列・JSON形式の配列・そのままの文字列のいずれか。
struct FrontMatter: Sendable, Equatable {
    var title: String?
    var description: String?
    var keywords: [String] = []
    var genre: String?
    var date: String?
    var appID: String?

    /// Markdownをフロントマターと本文に分ける
    static func split(_ source: String) -> (FrontMatter, String) {
        let normalized = source.replacingOccurrences(of: "\r\n", with: "\n")
        var lines = normalized.split(separator: "\n", omittingEmptySubsequences: false)
        guard lines.first?.trimmingCharacters(in: .whitespaces) == "---",
              let end = lines.dropFirst().firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == "---" })
        else {
            return (FrontMatter(), normalized)
        }

        var values: [String: String] = [:]
        for line in lines[1..<end] {
            guard let colon = line.firstIndex(of: ":") else { continue }
            let key = line[..<colon].trimmingCharacters(in: .whitespaces)
            let value = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
            values[key] = value
        }
        lines.removeSubrange(0...end)

        let frontMatter = FrontMatter(
            title: values["title"].flatMap(string),
            description: values["description"].flatMap(string),
            keywords: values["keywords"].map(list) ?? [],
            genre: values["genre"].flatMap(string),
            date: values["date"].flatMap(string),
            appID: values["appId"].flatMap(string)
        )
        return (frontMatter, lines.joined(separator: "\n"))
    }

    /// 文字列の値（空なら `nil`）
    private static func string(_ value: String) -> String? {
        let result: String
        if value.hasPrefix("\""), let decoded = try? JSONDecoder().decode(String.self, from: Data(value.utf8)) {
            result = decoded
        } else if value.hasPrefix("'"), value.hasSuffix("'"), value.count >= 2 {
            result = String(value.dropFirst().dropLast())
        } else {
            result = value
        }
        return result.isEmpty ? nil : result
    }

    /// 配列の値（`["a", "b"]`）
    private static func list(_ value: String) -> [String] {
        if let decoded = try? JSONDecoder().decode([String].self, from: Data(value.utf8)) {
            return decoded
        }
        return string(value).map { [$0] } ?? []
    }
}
