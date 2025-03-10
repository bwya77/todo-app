# Todo App for macOS

A minimal, sleek, responsive, and modern to-do application built for macOS using Swift and SwiftUI.

![UI Screenshot](/images/UI_main4.png)

## Features

- **Multiple Calendar Views**: Day, Week, Month, and Upcoming views for managing your tasks
- **Real-time Time Indicators**: Visual indicators showing the current time in Day and Week views
- **Project Completion Indicator**: visual indivator that fills like a pie chart as tasks are completed, providing an at-a-glance view of progress.
- **Sidebar Navigation**: Customizable sidebar with resizable width and collapsible design
- **Task Management**: Create, edit, and organize tasks with project support
- **Core Data Integration**: Persistent storage for all your tasks and projects
- **Modern UI**: Clean and minimalist design that follows macOS design guidelines
- **Elegant Animations**: Smooth transitions between months in the Upcoming view

## Month/Year Animation

The Upcoming view features elegant month and year transitions with custom animations:
- Smaller, more minimal display of month and year below the header
- Month in semibold font and year in thin font for improved visual hierarchy
- Smooth bottom-to-top transition animation when changing months
- The animation treats both month and year as a single unit for a cohesive look

Currently, the app uses a custom animation implementation. Future versions may integrate the AnimateText library for enhanced effects (see the `/todo-app/Presentation/Utilities/ANIMATION_README.md` for details).

## Collapsible Sidebar

The app features a collapsible sidebar that provides a more focused workspace when needed:

- **Toggle Button**: Located in the toolbar next to traffic light controls
- **Smooth Animation**: Uses SwiftUI spring animation for natural, responsive feel
- **State Preservation**: Remembers sidebar width when collapsing/expanding
- **Keyboard Support**: Compatible with standard macOS keyboard shortcuts
- **Adaptive Layout**: Main content dynamically expands to fill available space

See `/todo-app/Documentation/SidebarToggleFeature.md` for technical implementation details.

## Technologies

- Swift 5.7+
- SwiftUI
- Core Data
- Custom animation framework

## Requirements

- macOS 13.0+
- Xcode 14.0+

## Installation

1. Clone the repository:
   ```
   git clone https://github.com/username/todo-app.git
   ```

2. Open the project in Xcode:
   ```
   cd todo-app
   open todo-app.xcodeproj
   ```

3. Build and run the application (⌘+R)

## Project Structure

The project follows a clean architecture approach:

- **/Application**: App lifecycle and entry point
- **/Domain**: Core business logic and models
  - **/Models**: Core Data models for tasks, projects, and tags
- **/Infrastructure**: Implementation details
  - **/CoreData**: Database configuration and models
  - **/Persistence**: Storage and retrieval logic
- **/Presentation**: UI layer
  - **/Components**: Reusable UI components
  - **/Utilities**: Animation and other utility helpers
  - **/ViewModels**: Business logic for task management
  - **/Views**: SwiftUI views organized by feature:
    - **/Calendar**: Calendar-based views including day, week, month
    - **/Common**: Shared views like sidebar and content container
    - **/Task**: Task management interfaces

## Usage

- **Upcoming View**: Overview of upcoming tasks with calendar views
- **Inbox**: Quick access to incoming tasks
- **Today**: Focus on tasks due today
- **Projects**: Organize tasks by project
- **Custom Filters**: Filter tasks based on various criteria

## Development

### Time Indicator Customization

The app features custom time indicators in both Day and Week views. The positioning is carefully calibrated for accurate time representation:

- Day View: Uses a 3-minute time adjustment
- Week View: Uses a time adjustment with pixel-level fine-tuning

### .gitignore

For proper source control management, use the provided `.gitignore` file to exclude build artifacts:

```
# Xcode
build/
DerivedData/
*.xcuserstate
xcuserdata/

# Swift Package Manager
.build/
.swiftpm/

# macOS
.DS_Store
```

## Swift Package Manager Support

This project supports Swift Package Manager for easier dependency management and building:

```bash
# Build the project using SPM
swift build

# Run tests
swift test
```

The Package.swift file is configured to handle the SwiftUI app structure and properly include resources.

## Recent Changes

- Added collapsible sidebar with toolbar toggle button for expanded workspace
- Improved Upcoming view with smaller, more elegant month/year display
- Enhanced visual hierarchy with semibold month and thin year text
- Optimized month transition animations with smoother, faster performance
- Restructured project using clean architecture principles
