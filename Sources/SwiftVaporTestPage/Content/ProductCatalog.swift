/// `Content/<言語>/product.json` の内容（コンテンツページに並べるアプリやプロジェクト）
struct ProductCatalog: Codable, Sendable {
    struct Apps: Codable, Sendable {
        var development: [App]
        var transplanting: [App]
        var translation: [App]
    }

    struct Platform: Codable, Sendable {
        var os: String
        var version: String
    }

    struct Link: Codable, Sendable {
        var title: String
        var url: String
    }

    /// CMの動画（`url` はYouTubeの動画ID）
    struct Commercial: Codable, Sendable {
        var name: String
        var url: String
    }

    /// 移植したアプリの元になった拡張機能
    struct OriginalSource: Codable, Sendable {
        var platform: String
        var url: String
        var supportEmail: String
    }

    struct App: Codable, Sendable {
        var id: String
        var title: String
        var icon: String?
        var darkIcon: String?
        var description: String
        var supportedPlatforms: [Platform]
        var supportPage: String
        var feedback: String
        var media: [Link]?
        var cm: [Commercial]?
        var originalSource: OriginalSource?

        /// `id` に `id` の接頭辞がなければ付ける（App StoreのURL用）
        var appStoreID: String {
            id.hasPrefix("id") ? id : "id" + id
        }

        /// 数字だけのID（価格の取得用）
        var numericID: String {
            String(appStoreID.dropFirst(2))
        }
    }

    /// テンプレート・Blueskyフィード・Brave Goggleなど
    struct Other: Codable, Sendable {
        var id: String
        var title: String
        var label: String
        var description: String
        var repositoryUrl: String?
        var downloadUrl: String?
        var moreInfoUrl: String?
    }

    /// フレームワーク・シェルスクリプト・ウェブサイト
    struct Project: Codable, Sendable {
        var id: String
        var title: String
        var description: String
        var repositoryUrl: String?
        var downloadUrl: String?
    }

    var apps: Apps
    var others: [Other]
    var frameworks: [Project]
    var shellScripts: [Project]
    var websites: [Project]
    var trademarkNotices: [String]?

    /// 価格を表示するすべてのアプリ
    var allApps: [App] {
        apps.development + apps.transplanting + apps.translation
    }
}
