// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "TodoApp",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/richardtop/CalendarKit.git", from: "1.1.0")
    ],
    targets: [
        .target(
            name: "TodoApp",
            dependencies: ["CalendarKit"]
        )
    ]
)
