# Getting Started with Todo App

## Overview

Todo App is a sleek, responsive, and modern macOS application built with Swift, SwiftUI, and CoreData. It provides a comprehensive task management solution with projects, tags, and calendar views.

## Prerequisites

- macOS Monterey (12.0) or later
- Xcode 14.0 or later
- Swift 5.7 or later

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/todo-app.git
   cd todo-app
   ```

2. Open the project in Xcode:
   ```bash
   open todo-app.xcodeproj
   ```

3. Build and run the application (⌘+R).

## Project Structure

The Todo App follows a clean architecture pattern:

- **Application**: Contains app-level components like the App delegate
- **Domain**: Business logic, models, and entity interfaces
- **Infrastructure**: Implementation details, including CoreData setup
- **Presentation**: UI components, views, and view models

## Key Features

- **Task Management**: Create, edit, and organize tasks
- **Project Organization**: Group tasks into projects
- **Calendar Integration**: View tasks in daily, weekly, and monthly views
- **Tags and Filters**: Categorize and filter tasks with tags
- **Smart Lists**: Today, Upcoming, and Completed views
- **Performance Optimized**: Efficient data handling for large task collections

## Getting Started with Development

### CoreData Model

The app uses CoreData for persistence with the following main entities:

- **Item**: Represents a task with properties like title, due date, and completion status
- **Project**: A collection of tasks with properties like name and color
- **Tag**: Used for categorizing tasks

### Working with Tasks

```swift
// Create a new task
let newTask = Item.create(
    in: context,
    title: "Complete documentation",
    dueDate: Date().addingTimeInterval(86400), // Tomorrow
    priority: .medium,
    project: myProject
)

// Toggle task completion
task.toggleCompletion()

// Add a tag to a task
task.addTag(tagObject)
```

### Efficient Data Fetching

The app uses optimized fetch requests for better performance:

```swift
// Get today's tasks
let todayTasks = TaskFetchRequestFactory.todayTasks(in: context)

// Use NSFetchedResultsController for a view
let controller = TaskFetchedResultsController(
    viewType: .today,
    context: viewContext
)
```

## Further Documentation

For more detailed information, refer to the specific documentation sections:

- [Architecture Documentation](../Architecture/README.md)
- [Feature Documentation](../Features/README.md)

## Changelog

For a complete list of changes and version information, see the [Changelog](./CHANGELOG.md).
