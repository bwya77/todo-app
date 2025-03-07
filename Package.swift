// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "todo-app",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "todo-app", targets: ["TodoApp"])
    ],
    dependencies: [
        .package(url: "https://github.com/richardtop/CalendarKit.git", from: "1.1.0")
    ],
    targets: [
        .executableTarget(
            name: "TodoApp",
            dependencies: [.product(name: "CalendarKit", package: "calendarkit")],
            path: "todo-app",
            resources: [
                .process("Assets.xcassets"),
                .process("Preview Content/Preview Assets.xcassets"),
                .process("Info.plist"),
                .process("todo_app.entitlements"),
                .process("todo_app.xcdatamodeld")
            ]
        ),
        .testTarget(
            name: "TodoAppTests",
            dependencies: ["TodoApp"],
            path: "todo-appTests"
        ),
        .testTarget(
            name: "TodoAppUITests",
            dependencies: ["TodoApp"],
            path: "todo-appUITests"
        )
    ]
)
