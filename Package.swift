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
        // CalendarKit removed - not compatible with macOS
    ],
    targets: [
        .executableTarget(
            name: "TodoApp",
            dependencies: [
                // No external dependencies
            ],
            path: "todo-app",
            exclude: ["Views/MonthCalendarViewFix.swift.bak"],
            resources: [
                .process("Assets.xcassets"),
                .process("Preview Content/Preview Assets.xcassets"),
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
