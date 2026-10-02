---
title: macOSの特定のパスにアクセスして、読み書きを行う
description: Sandboxによって、アクセスすることが困難な特定のパスについて簡単にアクセスする方法を解説する。エンタイトルメントファイルを適切に編集することで、サンドボックス外のファイルを読み書きできる。
keywords: ["Swift", "Sandbox", "macOS"]
genre: Swift
date: 2025/9/9
---
# macOSの特定のパスにアクセスして、読み書きを行う
macOSアプリにおいて、サンドボックスの制約上自由にファイルにアクセスすることはできません。ほとんどの場合において、サンドボックス内のURLが返されるからです。今回は、Sandboxの制約を守りつつHomeリレクトリ直下の特定のパスにアクセスする方法を学びます。
実際に、App Reviewを通過した方法のため問題のない方法です。ぜひ、採用してみてはどうでしょうか。

## 環境
- macOS 15.4 (Sequoia)
- Xcode 16.3
  
## 今までの方法
これは、Stack Overflowではこのような方法が書かれていることがあります。
```swift
extension FileManager {
    static var homeDirectoryURL: URL? {
        guard let pw = getpwuid(getuid()), let home = pw.pointee.pw_dir else { return nil }
        let homePath = self.default.string(withFileSystemRepresentation: home,
                                           length: strlen(home))
        return URL(fileURLWithPath: homePath)
    }
}

let home = FileManager.homeDirectoryURL
```
このURLに特定のパスを追加すれば、直下のファイルにアクセスできるはずです。
これは、今も実際に動作する方法ですが、趣のある方法です。みたことのない関数があります。getpwuidとかgetuidはObjective-Cで定義されているように見えます。

古きコードの良さももちろんありますが、Swiftでよりシンプルにアクセスしたいでしょう。そこで、いろいろ試してみると以下の方法でアクセスできました。
## 簡単な方法
実は、コードとしては恐ろしいほど簡単です。今回は~/.ssh/configで試してみます。
```swift
func getSSHConfigDirectoryURL() -> URL? {
    guard let userName = ProcessInfo.processInfo.environment["USER"] else { return nil }
    return URL(string: "file:///Users/\(user)/.ssh/config")
}
```
これは、みんなが理解できるコードかと思います。もちろん試したこともあるはずです。これだけではうまくいかないのですが、使用するのはこのコードです。
これでアクセスするようにするには、実はエンタイトルメントファイルに以下の内容を追加するだけです。
```plist
	<key>com.apple.security.temporary-exception.files.home-relative-path.read-write</key>
	<array>
		<string>/.ssh/</string>
	</array>
```
これでアクセスができるはずです。

## 最後に
エンタイトルメントファイルに上の内容を追加するだけということで、アクセスすることができました。エンタイトルファイルが必要な関係上、すべてのプロジェクトで採用できるわけではないと思いますが、とても簡単な方法で、回避策ではない安全な方法ではないでしょうか。

## 参考資料
- [How to get user home directory path (Users/"user name") without knowing the username in Swift3](https://stackoverflow.com/questions/41383054/how-to-get-user-home-directory-path-users-user-name-without-knowing-the-user)
- [App Sandbox Temporary Exception Entitlements](https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/AppSandboxTemporaryExceptionEntitlements.html)