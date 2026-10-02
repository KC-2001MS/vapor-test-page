// swift-tools-version:6.4
import PackageDescription

let package = Package(
    name: "SwiftVaporTestPage",
    platforms: [
       .macOS(.v13)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.122.2"),
        // 🍃 An expressive, performant, and extensible templating language built for Swift.
        .package(url: "https://github.com/vapor/leaf.git", from: "4.5.2"),
        // 📝 Markdown parser maintained by the Swift project.
        .package(url: "https://github.com/swiftlang/swift-markdown.git", from: "0.9.0"),
        // 🔵 Non-blocking, event-driven networking for Swift. Used for custom executors
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.103.0"),
    ],
    targets: [
        .executableTarget(
            name: "SwiftVaporTestPage",
            dependencies: [
                .product(name: "Leaf", package: "leaf"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Markdown", package: "swift-markdown"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "SwiftVaporTestPageTests",
            dependencies: [
                .target(name: "SwiftVaporTestPage"),
                .product(name: "VaporTesting", package: "vapor"),
            ],
            swiftSettings: swiftSettings
        )
    ]
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("ExistentialAny"),
] }
