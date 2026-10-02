import Vapor

/// 存在しないページで、サイトの404ページを表示する（開発用サーバー）
///
/// GitHub Pagesでは書き出した `404.html` が表示されるため、サーバーでも同じ見た目にする。
struct NotFoundPageMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        do {
            return try await next.respond(to: request)
        } catch let error as any AbortError where error.status == .notFound {
            let path = request.url.path

            // 元サイトの本文には `./privacy.html` のようなリンクがある。GitHub Pagesでは書き出したファイルが表示されるため、サーバーでは拡張子なしのページへ転送する
            if path.hasSuffix(".html") {
                return request.redirect(to: String(path.dropLast(5)))
            }

            let view = try await SiteController().notFound(request, SiteLanguage(path: path))
            let response = try await view.encodeResponse(for: request)
            response.status = .notFound
            return response
        }
    }
}
