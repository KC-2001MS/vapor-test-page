import Leaf
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // サイトの設定とコンテンツ（Content/ のMarkdown・JSON）を読み込む
    app.siteConfiguration = .fromEnvironment()
    app.siteContent = try SiteContent(directory: app.directory.workingDirectory + "Content")

    // App Storeの価格（テストではネットワークに接続しない）
    app.appStorePrices = AppStorePrices(
        client: app.environment == .testing ? nil : app.client,
        logger: app.logger
    )

    // 存在しないページではサイトの404ページを表示し、Public/ のファイル（CSS・画像など）を配信する
    app.middleware.use(NotFoundPageMiddleware())
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.views.use(.leaf)

    // register routes
    try routes(app)

    // 静的なHTMLを書き出すコマンド（swift run VaporTestPage export）
    app.asyncCommands.use(ExportCommand(), as: "export")
}
