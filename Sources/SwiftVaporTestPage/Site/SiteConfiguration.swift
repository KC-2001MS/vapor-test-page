import Vapor

/// サイト全体の設定
struct SiteConfiguration: Sendable {
    /// 本番サイトのURL（canonical・OGPのURLに使う）
    static let siteURL = "https://iroiro.dev"

    /// サイトを置くパス（例：`/vapor-test-page`。ルートに置く場合は空）
    /// GitHub Pagesのプロジェクトサイトはリポジトリ名のパスに公開されるため、リンクや画像のURLの先頭に付ける
    var basePath: String
    /// Google AnalyticsのID（未設定なら計測用のスクリプトを出力しない）
    var analyticsID: String?

    /// 環境変数 `SITE_BASE_PATH`・`GA_MEASUREMENT_ID` から読み込む
    static func fromEnvironment() -> SiteConfiguration {
        SiteConfiguration(
            basePath: normalize(basePath: Environment.get("SITE_BASE_PATH") ?? ""),
            analyticsID: Environment.get("GA_MEASUREMENT_ID").flatMap { $0.isEmpty ? nil : $0 }
        )
    }

    /// `/` で始まり、`/` で終わらない形にする（`vapor-test-page/` → `/vapor-test-page`）
    static func normalize(basePath: String) -> String {
        let trimmed = basePath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return trimmed.isEmpty ? "" : "/" + trimmed
    }
}

extension Application {
    private struct SiteConfigurationKey: StorageKey {
        typealias Value = SiteConfiguration
    }

    var siteConfiguration: SiteConfiguration {
        get { storage[SiteConfigurationKey.self] ?? SiteConfiguration(basePath: "", analyticsID: nil) }
        set { storage[SiteConfigurationKey.self] = newValue }
    }
}
