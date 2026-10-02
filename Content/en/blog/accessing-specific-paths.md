---
title: Access specific paths on macOS to read and write data
description: This guide explains how to easily access specific paths that are difficult to reach using Sandbox. By properly editing the entitlement file, you can read and write files outside the sandbox.
keywords: ["Swift", "Sandbox", "macOS"]
genre: Swift
date: 2025/9/9
---
# Accessing and reading/writing specific paths on macOS
Due to sandboxing constraints, macOS apps cannot freely access files. In most cases, this is because URLs within the sandbox are returned. This time, we'll learn how to access specific paths directly under the Home directory while adhering to sandboxing restrictions.
This method has actually passed App Review, so it's a safe approach. Why not give it a try?

## 環境
- macOS 15.4 (Sequoia)
- Xcode 16.3
  
## Previous Methods
This is a method sometimes described on Stack Overflow.
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
Adding a specific path to this URL should allow you to access the files directly under it.
This method still works today, and it's quite charming. There are some functions I haven't seen before. getpwuid and getuid appear to be defined in Objective-C.

While there's certainly merit in the old code, you'll likely want simpler access in Swift. After trying various approaches, I found the following method worked.
## The Simple Method
Actually, the code is terrifyingly simple. This time, we'll try it in ~/.ssh/config.
```swift
func getSSHConfigDirectoryURL() -> URL? {
    guard let userName = ProcessInfo.processInfo.environment["USER"] else { return nil }
    return URL(string: "file:///Users/\(user)/.ssh/config")
}
```
This is code that everyone should be able to understand. Of course, you've probably tried it before. While this alone won't work, this is the code we'll be using.
To enable access with this, all you actually need to do is add the following content to the entitlement file.
```plist
	<key>com.apple.security.temporary-exception.files.home-relative-path.read-write</key>
	<array>
		<string>/.ssh/</string>
	</array>
```
You should now be able to access it.

## Finally
Simply adding the above content to the entitlement file allowed me to gain access. While it may not be applicable to all projects due to the necessity of an entitlement file, this seems like a very simple method—not a workaround, but a secure solution.

## Reference Materials
- [How to get user home directory path (Users/"user name") without knowing the username in Swift3](https://stackoverflow.com/questions/41383054/how-to-get-user-home-directory-path-users-user-name-without-knowing-the-user)
- [App Sandbox Temporary Exception Entitlements](https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/AppSandboxTemporaryExceptionEntitlements.html)