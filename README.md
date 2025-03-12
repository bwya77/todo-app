# Todo App for macOS

A minimal, sleek, responsive, and modern to-do application built for macOS using Swift and SwiftUI.

![UI Screenshot](/images/UI_main4.png)

## Features

### Project Selection Color
The Selection color for projects is based on the project color. Here you can see Health was chosen as red so the project status icon is red and the Add Task button is red. When you check an item as complete, the checkbox also follows the project color.
![Project viewt](/images/ProjectView.png)

### Multiple Calendar Views*
View all your tasks by Day, Week, Month, and Upcoming views for managing your tasks
![day view](/images/DayView.png)
![week view](/images/WeekView.png)
![month view](/images/MonthView.png)

### Real-time Time Indicators
Visual indicators showing the current time in Day and Week views
![day view](/images/DayView.png)

### Project Completion Indicator
Visual indicator that fills like a pie chart as tasks are completed, providing an at-a-glance view of progress. The completion indicator smoothly transitions from empty to full based on task completion
![project status](/images/projectstatus.gif)

## *Sidebar Navigation
Customizable sidebar with resizable width and collapsible design
- ![sidebar](/images/sidebar.gif)

### Project Logged Tasks
When a task is completed, it will transition to the bottom of the project view. You are able to view logged items and unlog them if needed.
![logged tasks](/images/LoggedTasks.gif)

### Month/Year Animation

The Upcoming view features elegant month and year transitions with custom animations:
- Smaller, more minimal display of month and year below the header
- Month in semibold font and year in thin font for improved visual hierarchy
- Smooth bottom-to-top transition animation when changing months
- The animation treats both month and year as a single unit for a cohesive look

![logged tasks](/images/monthTransition.gif)


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


## Development

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
