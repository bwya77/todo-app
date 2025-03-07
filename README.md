# Todo App for macOS

A minimal, sleek, responsive, and modern to-do application built for macOS using Swift and SwiftUI.

![UI Screenshot](/images/UI_main2.png)

## Features

- **Multiple Calendar Views**: Day, Week, and Month calendar views for managing your tasks
- **Real-time Time Indicators**: Visual indicators showing the current time in Day and Week views
- **Sidebar Navigation**: Customizable sidebar with resizable width
- **Task Management**: Create, edit, and organize tasks with project support
- **Core Data Integration**: Persistent storage for all your tasks and projects
- **Modern UI**: Clean and minimalist design that follows macOS design guidelines

## Technologies

- Swift 5.7+
- SwiftUI
- Core Data
- CalendarKit integration

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

- **Models**: Core Data models for tasks, projects, and tags
- **Views**: SwiftUI views including calendar implementations and task lists
- **ViewModels**: Business logic for task management
- **Custom Components**: Specialized UI components including time indicators and calendar views

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

## Acknowledgements

- [CalendarKit](https://github.com/richardtop/CalendarKit) - Used for enhanced calendar views
