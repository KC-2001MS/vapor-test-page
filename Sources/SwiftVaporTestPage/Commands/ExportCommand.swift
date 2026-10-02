import Foundation
import Vapor

/// サイトを静的なファイルとして書き出す（GitHub Pages用）
///
///     swift run SwiftVaporTestPage export [--output dist]
///
/// サーバーと同じルートに内部でリクエストを送り、返ってきたHTMLをファイルに保存する。
/// そのため、`swift run` で確認したページと書き出したページは同じ内容になる。
/// `Public/` のファイル（CSS・画像・フォント）もそのままコピーする。
struct ExportCommand: AsyncCommand {
    struct Signature: CommandSignature {
        @Option(name: "output", short: "o", help: "Output directory (default: dist)")
        var output: String?
    }

    var help: String {
        "Exports the site as static HTML files for GitHub Pages."
    }

    func run(using context: CommandContext, signature: Signature) async throws {
        let app = context.application
        let fileManager = FileManager.default
        let output = URL(fileURLWithPath: signature.output ?? app.directory.workingDirectory + "dist", isDirectory: true)

        // 前回の書き出しを消してから、Public/ をコピーする
        if fileManager.fileExists(atPath: output.path) {
            try fileManager.removeItem(at: output)
        }
        try fileManager.createDirectory(at: output, withIntermediateDirectories: true)
        let publicDirectory = URL(fileURLWithPath: app.directory.publicDirectory, isDirectory: true)
        for item in try fileManager.contentsOfDirectory(atPath: publicDirectory.path) where !item.hasPrefix(".") {
            try fileManager.copyItem(at: publicDirectory.appendingPathComponent(item), to: output.appendingPathComponent(item))
        }
        // GitHub PagesのJekyllの処理を止める（_ で始まるファイルなども、そのまま公開する）
        try Data().write(to: output.appendingPathComponent(".nojekyll"))

        let paths = SiteController.allPaths(content: app.siteContent)
        for path in paths {
            let html = try await render(path, app: app)
            let file = output.appendingPathComponent(Self.filePath(for: path))
            try fileManager.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
            try html.write(to: file)
            context.console.print("\(path) → \(Self.filePath(for: path))")
        }
        context.console.success("Exported \(paths.count) pages to \(output.path)")
    }

    /// サーバーのルートにリクエストを送り、HTMLを受け取る
    private func render(_ path: String, app: Application) async throws -> Data {
        let request = Request(application: app, method: .GET, url: URI(path: path), on: app.eventLoopGroup.any())
        let response = try await app.responder.respond(to: request).get()
        guard response.status == .ok else {
            throw Abort(response.status, reason: "Failed to render \(path)")
        }
        let body = try await response.body.collect(on: request.eventLoop).get()
        return Data(body?.readableBytesView ?? ByteBuffer().readableBytesView)
    }

    /// ページのパスから保存するファイルのパスを決める
    ///
    /// GitHub Pagesは `/product` へのアクセスに `product.html` を返し、`/en/` には `en/index.html` を返す。
    static func filePath(for path: String) -> String {
        let trimmed = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if trimmed.isEmpty {
            return "index.html"
        }
        return path.hasSuffix("/") ? trimmed + "/index.html" : trimmed + ".html"
    }
}
