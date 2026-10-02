import Vapor

/// サイトのすべてのページ
///
/// 日本語はルート、英語は `/en` 以下に同じ構成のページを登録する。
/// 静的書き出し（`export` コマンド）は `allPaths(content:)` のページを順にリクエストしてHTMLを保存する。
struct SiteController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        for language in SiteLanguage.allCases {
            let root = language == .english ? routes.grouped("en") : routes

            root.get { req in try await home(req, language) }
            root.get("404") { req in try await notFound(req, language) }
            root.get("product") { req in try await product(req, language) }
            root.get("product", ":slug") { req in try await article(req, language, .product) }
            root.get("product", "tips", ":slug") { req in try await article(req, language, .tips) }
            root.get("blog") { req in try await articleList(req, language, .blog) }
            root.get("blog", ":slug") { req in try await article(req, language, .blog) }
            root.get("newsroom") { req in try await articleList(req, language, .newsroom) }
            root.get("newsroom", ":slug") { req in try await article(req, language, .newsroom) }
            root.get("contact") { req in try await contact(req, language) }
            root.get("privacy") { req in try await staticPage(req, language, "privacy", .privacy(language)) }
            root.get("agreement") { req in try await staticPage(req, language, "agreement", .agreement(language)) }
        }
    }

    /// 静的書き出しするすべてのパス（言語の接頭辞を含む）
    static func allPaths(content: SiteContent) -> [String] {
        var paths: [String] = []
        for language in SiteLanguage.allCases {
            let prefix = language.pathPrefix
            paths.append(prefix.isEmpty ? "/" : prefix + "/")
            paths += ["/404", "/product", "/blog", "/newsroom", "/contact", "/privacy", "/agreement"].map { prefix + $0 }
            for section in ArticleSection.allCases {
                paths += content[language].articles(in: section).map { "\(prefix)/\(section.path)/\($0.slug)" }
            }
        }
        return paths
    }

    // MARK: - ページ

    private func home(_ req: Request, _ language: SiteLanguage) async throws -> View {
        try await render(req, "home", language, .home(language), EmptyPage())
    }

    func notFound(_ req: Request, _ language: SiteLanguage) async throws -> View {
        try await render(req, "not-found", language, .notFound(language), EmptyPage())
    }

    private func staticPage(_ req: Request, _ language: SiteLanguage, _ name: String, _ metadata: PageMetadata) async throws -> View {
        try await render(req, name, language, metadata, EmptyPage())
    }

    private func contact(_ req: Request, _ language: SiteLanguage) async throws -> View {
        let content = req.application.siteContent[language]
        let html = renderer(req, imageClass: nil).render(content.contact.body)
        return try await render(req, "article", language, .contact(language), ArticlePage(html: html, showsDonation: false))
    }

    private func article(_ req: Request, _ language: SiteLanguage, _ section: ArticleSection) async throws -> View {
        let slug = try req.parameters.require("slug")
        guard let article = req.application.siteContent[language].article(slug, in: section) else {
            throw Abort(.notFound)
        }
        let html = renderer(req, imageClass: section.usesMarkdownImageClass ? "markdown-image" : nil).render(article.body)
        var site = layout(req, language, .article(article, in: section, language))
        if section.loadsSocialEmbeds {
            site.loadsTwitter = html.contains("twitter-tweet")
            site.loadsBluesky = html.contains("bluesky-embed")
        }
        let page = ArticlePage(html: html, showsDonation: section.showsDonation)
        return try await req.view.render("article", PageContext(site: site, page: page))
    }

    private func articleList(_ req: Request, _ language: SiteLanguage, _ section: ArticleSection) async throws -> View {
        let strings = language.strings
        let home = req.application.siteConfiguration.basePath + language.pathPrefix
        let items = req.application.siteContent[language].articles(in: section).map { article in
            ArticleListPage.Item(
                title: article.frontMatter.title ?? "",
                description: article.frontMatter.description ?? "",
                genre: article.frontMatter.genre ?? "",
                date: article.frontMatter.date ?? "",
                url: "\(home)/\(section.path)/\(article.slug)"
            )
        }
        let page = ArticleListPage(
            heading: section == .blog ? strings.blogHeading : strings.newsroomHeading,
            emptyMessage: section == .blog ? strings.noBlogPosts : strings.noNews,
            items: items
        )
        return try await render(req, "article-list", language, .articleList(section, language), page)
    }

    private func product(_ req: Request, _ language: SiteLanguage) async throws -> View {
        let catalog = req.application.siteContent[language].catalog
        let base = req.application.siteConfiguration.basePath
        let prices = req.application.appStorePrices

        func card(_ app: ProductCatalog.App, isTranslation: Bool = false) async -> ProductPage.AppCard {
            let descriptionHTML: String
            if isTranslation, language == .japanese {
                // 翻訳したアプリは、説明の先頭のアプリ名を太字にする
                descriptionHTML = "<strong>\(HTML.escape(app.title))</strong>" + HTML.escape(app.description.replacingOccurrences(of: app.title + "は", with: "は"))
            } else {
                descriptionHTML = HTML.escape(app.description)
            }
            return ProductPage.AppCard(
                title: app.title,
                appStoreURL: "https://apps.apple.com/app/\(app.appStoreID)",
                // ファイル名に空白があるため、srcset で区切りと誤解されないようにエンコードする
                iconURL: app.icon.map { base + HTML.encodePath($0) },
                darkIconURL: app.darkIcon.map { base + HTML.encodePath($0) },
                iconAlt: language == .english ? "\(app.title) Icon" : "\(app.title)アイコン",
                platforms: app.supportedPlatforms.map { "\($0.os) \($0.version)~" },
                descriptionHTML: descriptionHTML,
                supportPage: app.supportPage,
                feedback: app.feedback,
                price: await prices.price(appID: app.numericID, language: language),
                commercials: app.cm ?? [],
                media: app.media ?? [],
                originalSource: language == .japanese ? app.originalSource : nil,
                englishContactNote: isTranslation && language == .english
                    ? "If you have any questions and feedback, please contact \(app.feedback.replacingOccurrences(of: "mailto:", with: "")) in English."
                    : nil
            )
        }

        var development: [ProductPage.AppCard] = []
        for app in catalog.apps.development { development.append(await card(app)) }
        var transplanting: [ProductPage.AppCard] = []
        for app in catalog.apps.transplanting { transplanting.append(await card(app)) }
        var translation: [ProductPage.AppCard] = []
        for app in catalog.apps.translation { translation.append(await card(app, isTranslation: true)) }

        let page = ProductPage(
            appSections: [
                ProductPage.AppSection(heading: language.strings.development, apps: development, isFollowing: false),
                ProductPage.AppSection(heading: language.strings.transplanting, apps: transplanting, isFollowing: true),
                ProductPage.AppSection(heading: language.strings.translation, apps: translation, isFollowing: true),
            ],
            others: catalog.others.map {
                ProductPage.Other(
                    title: $0.title, label: $0.label, description: $0.description,
                    isTemplate: $0.label == language.strings.templateLabel,
                    repositoryUrl: $0.repositoryUrl, downloadUrl: $0.downloadUrl, moreInfoUrl: $0.moreInfoUrl
                )
            },
            frameworks: catalog.frameworks,
            shellScripts: catalog.shellScripts,
            websites: catalog.websites,
            // 商標の注記は日本語版だけに表示する
            trademarkNotices: language == .japanese
                ? (catalog.trademarkNotices ?? []).enumerated().map { "\($0.offset + 1).\($0.element)" }
                : [],
            appStoreBadgeLight: "\(base)/images/badges/app-store-\(language.rawValue)-black.svg",
            appStoreBadgeDark: "\(base)/images/badges/app-store-\(language.rawValue)-white.svg"
        )
        return try await render(req, "product", language, .product(language), page)
    }

    // MARK: - 補助

    private func layout(_ req: Request, _ language: SiteLanguage, _ metadata: PageMetadata) -> LayoutContext {
        LayoutContext(language: language, metadata: metadata, configuration: req.application.siteConfiguration)
    }

    private func renderer(_ req: Request, imageClass: String?) -> MarkdownRenderer {
        MarkdownRenderer(basePath: req.application.siteConfiguration.basePath, imageClass: imageClass)
    }

    private func render<Page: Encodable & Sendable>(_ req: Request, _ template: String, _ language: SiteLanguage, _ metadata: PageMetadata, _ page: Page) async throws -> View {
        try await req.view.render(template, PageContext(site: layout(req, language, metadata), page: page))
    }
}
