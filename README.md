# VaporTestPage

[いろいろポートフォリオ（iroiro.dev）](https://iroiro.dev)を、Vapor と Leaf でどこまで再現できるかを試す検証用のページです。
本番サイトを置き換える予定はありません。

Vapor はサーバーとして動かすフレームワークですが、GitHub Pages ではサーバーを動かせません。
そこで、ビルド時に Vapor を起動して各ページを HTML に書き出し、そのファイルを GitHub Pages に公開します。

- 開発中は `swift run` でサーバーを起動し、ブラウザで確認する
- 公開時は `swift run VaporTestPage export` で `dist/` に静的なファイルを書き出す

書き出しは、サーバーと同じルートに内部でリクエストを送り、返ってきた HTML を保存しています。
そのため、サーバーで確認したページと公開されるページは同じ内容になります。

## 必要なもの

- Swift 6.4 以降

## 使い方

```bash
# サーバーを起動（http://localhost:8080）
swift run

# テスト
swift test

# 静的なファイルを dist/ に書き出す
swift run VaporTestPage export

# GitHub Pages と同じく /vapor-test-page/ 以下に置く前提で書き出す
SITE_BASE_PATH=/vapor-test-page swift run VaporTestPage export
```

| 環境変数 | 内容 |
| ---- | ---- |
| `SITE_BASE_PATH` | サイトを置くパス。リンク・画像・CSS の URL の先頭に付ける（既定は空＝ルート） |
| `GA_MEASUREMENT_ID` | Google Analytics の ID。未設定なら計測用のスクリプトを出力しない |

## 再現している範囲

元サイト（Next.js）の日本語版と英語版（`/en` 以下）を対象にしています。文面は元サイトと同じです。

| ページ | パス | 内容の出どころ |
| ---- | ---- | ---- |
| トップ | `/` | （固定の文言） |
| コンテンツ | `/product` | `Content/ja/product.json` |
| アプリの詳細 | `/product/:slug` | `Content/ja/product/*.md` |
| Tips | `/product/tips/:slug` | `Content/ja/tips/*.md` |
| ブログ | `/blog`・`/blog/:slug` | `Content/ja/blog/*.md` |
| ニュースルーム | `/newsroom`・`/newsroom/:slug` | `Content/ja/newsroom/*.md` |
| 問い合わせ | `/contact` | `Content/ja/contact.md` |
| プライバシーポリシー・利用規約 | `/privacy`・`/agreement` | `Resources/Views/pages/ja/*.leaf` |
| 404 | 上記以外 | （固定の文言） |

`Content/ja`・`Content/en` は元サイトの `content/ja`・`content/en` をそのまま同梱したものです。
CSS（`Public/css/`）も元サイトのものを使っています。CSS Modules のファイルは、通常の CSS に書き換えています。

## 構成

| ファイル | 内容 |
| ---- | ---- |
| `Sources/VaporTestPage/Controllers/SiteController.swift` | すべてのページのルートと、書き出すパスの一覧 |
| `Sources/VaporTestPage/Commands/ExportCommand.swift` | 静的なファイルを書き出す `export` コマンド |
| `Sources/VaporTestPage/Markdown/` | Markdown から HTML への変換（swift-markdown を使用） |
| `Sources/VaporTestPage/Content/` | `Content/` の Markdown・JSON の読み込み |
| `Resources/Views/` | Leaf のテンプレート |
| `.github/workflows/pages.yml` | テスト・書き出し・GitHub Pages への公開 |

Markdown は、Swift プロジェクトが管理する [swift-markdown](https://github.com/swiftlang/swift-markdown) で解析し、
元サイトの remark（remark-gfm・remark-breaks）＋ rehype-raw と同じ HTML になるように変換しています。
swift-markdown が対応していない脚注（`[^1]`）は、解析の前に処理しています。

## 元サイトとの違い

- 価格は元サイトと同じくビルド時に取得します（日本語版は日本、英語版はアメリカの App Store）。テストでは取得せず「―」と表示します。
- 英語版のライトモードの App Store バッジは、元サイトでは画像のパスの誤りで表示されないため、正しい黒のバッジを表示しています。
- アプリのアイコンのダークモード用の画像は、元サイトではファイル名の空白のため `srcset` が正しく読み込まれません。URL をエンコードして表示しています。
- Google Analytics は、本番サイトの計測に混ざらないよう、`GA_MEASUREMENT_ID` を設定したときだけ出力します。

## GitHub Pages への公開

`main` ブランチに push すると、GitHub Actions（`.github/workflows/pages.yml`）がテスト・書き出し・公開を行います。
リポジトリの Settings → Pages → Build and deployment の Source を「GitHub Actions」にしておく必要があります。
