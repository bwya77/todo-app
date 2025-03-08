# Todo App

A macOS task management application with calendar integration and scheduling features.

## Recent Build Error Fix (March 8, 2025)

If you're encountering build errors with SwiftUI syntax or CalendarKit dependencies, run:

```bash
chmod +x fix-build-errors.sh
./fix-build-errors.sh
```

This script will:
1. Fix syntax errors in DayCalendarView.swift
2. Update the deprecated WheelEventHandler.swift
3. Remove any iOS-only dependencies that aren't compatible with macOS
4. Clean and rebuild the project

For detailed information, see:
- `todo-app/BUILD_FIXES_MARCH_8.md`

## Required Manual Steps

After running the fix script, you'll need to:

1. Open the project in Xcode
2. Select the project file in Project Navigator
3. Select the 'todo-app' target
4. Go to 'Build Phases' tab
5. Expand 'Copy Bundle Resources'
6. Remove 'Info.plist' and any README.md files from this list
7. Clean the project (Product > Clean Build Folder) and build again

### AnimateText Library Integration (Optional)

The Upcoming view uses a custom animation for month transitions. To enable the complete animation experience with the AnimateText library:

1. Open the project in Xcode
2. Go to File > Add Package Dependencies...
3. Enter URL: `https://github.com/jasudev/AnimateText.git`
4. Select branch: `main`
5. Click Add Package

Alternatively, you can manually edit Package.swift to add:
```swift
dependencies: [
    .package(url: "https://github.com/jasudev/AnimateText.git", .branch("main"))
],
targets: [
    .executableTarget(
        name: "TodoApp",
        dependencies: [
            .product(name: "AnimateText", package: "AnimateText")
        ],
        // ...
    ),
]
```

For more details, see `/todo-app/Presentation/Utilities/ANIMATION_README.md`

## Project Structure

The project follows a clean architecture approach:
- **Application**: App entry point and configuration
- **Domain**: Business logic and models
- **Presentation**: UI components and views 
- **Infrastructure**: Technical services
- **Resources**: Static assets

## Calendar Features

The app includes custom calendar views for:
- Month view with task indicators
- Week view with time-based scheduling
- Day view with hourly task breakdown

All calendar views support gesture-based navigation through swiping and trackpad gestures.
