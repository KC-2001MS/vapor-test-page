import Vapor

/// App Storeの価格（iTunes Search APIで取得する）
///
/// 元サイトと同じく、ページを作るとき（静的書き出しではビルド時）に取得する。
/// 同じアプリ・国は一度だけ取得し、結果を覚えておく。
actor AppStorePrices {
    private struct LookupResponse: Decodable {
        struct Result: Decodable {
            var formattedPrice: String?
        }
        var results: [Result]
    }

    /// 価格を取得しないときの表示
    static let unavailable = "―"

    private let client: (any Client)?
    private let logger: Logger
    private var cache: [String: String] = [:]

    /// - Parameter client: `nil` なら価格を取得しない（テスト用）
    init(client: (any Client)?, logger: Logger) {
        self.client = client
        self.logger = logger
    }

    /// 表示用の価格（取得できなかった場合は元サイトと同じメッセージ）
    func price(appID: String, language: SiteLanguage) async -> String {
        let key = "\(language.appStoreCountry)/\(appID)"
        if let cached = cache[key] {
            return cached
        }
        let price = await fetch(appID: appID, country: language.appStoreCountry)
        cache[key] = price
        return price
    }

    private func fetch(appID: String, country: String) async -> String {
        guard let client else {
            return Self.unavailable
        }
        let uri = URI(string: "https://itunes.apple.com/lookup?id=\(appID)&country=\(country)")
        do {
            let response = try await client.get(uri) { request in
                request.timeout = .seconds(10)
            }
            // iTunes Search APIはContent-Typeが text/javascript のため、JSONとして直接デコードする
            let lookup = try JSONDecoder().decode(LookupResponse.self, from: Data(response.body?.readableBytesView ?? ByteBuffer().readableBytesView))
            guard let result = lookup.results.first else {
                return "App not found"
            }
            return result.formattedPrice ?? "Free"
        } catch {
            logger.warning("Error fetching price for id \(appID): \(error)")
            return "Error fetching price"
        }
    }
}

extension Application {
    private struct AppStorePricesKey: StorageKey {
        typealias Value = AppStorePrices
    }

    var appStorePrices: AppStorePrices {
        get {
            guard let prices = storage[AppStorePricesKey.self] else {
                fatalError("AppStorePrices is not configured. Set app.appStorePrices in configure(_:).")
            }
            return prices
        }
        set { storage[AppStorePricesKey.self] = newValue }
    }
}
