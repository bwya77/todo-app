# CoreData Model Documentation

This directory contains the CoreData model for the to-do application, along with extension files that provide additional functionality for the entities.

## Model Overview

The data model consists of three main entities:

1. **Item**: Represents a task or to-do item
2. **Project**: Represents a collection of related items
3. **Tag**: Represents a label that can be applied to items for categorization

## Recent Optimizations

The CoreData model has been optimized in the following ways:

### 1. Proper Validation and Default Values

- All required attributes now have default values to prevent nil values
- UUIDs are automatically generated for new entities
- Date fields have appropriate default values
- String fields have sensible default values

### 2. Appropriate Optionality

- Required attributes are marked as non-optional
- Timestamp fields (creation date, etc.) are non-optional with defaults
- Only truly optional fields like notes, dueDate, and completionDate remain optional

### 3. Delete Rules for Relationships

- Project → Items: Cascade - When a project is deleted, all of its items are deleted
- Tag ↔ Items: Nullify - When a tag is deleted, the connection is removed but items remain
- Item → Project: Nullify - When an item is deleted, the project remains unchanged

### 4. Extension Methods

Extension methods have been added to provide:

- Factory methods for creating properly initialized entities
- Convenience methods for common operations
- Helper methods for working with relationships
- Built-in validation logic

## Migration Support

The model includes support for migrating from earlier versions:

- Automatic lightweight migration is enabled
- A custom migration policy handles edge cases
- Validation methods ensure data integrity during migration

## Priority Enum

A `Priority` enum has been added to replace the raw Int16 values previously used:

```swift
enum Priority: Int16 {
    case none = 0
    case low = 1
    case medium = 2
    case high = 3
}
```

This provides type safety and clear semantic meaning when working with priority values.

## Usage Examples

### Creating a new task in a project:

```swift
// Using the project extension method
let task = myProject.addTask(title: "New task", dueDate: tomorrow, priority: .medium)

// Or using the Item factory method
let task = Item.create(in: context, title: "New task", dueDate: tomorrow, priority: .medium, project: myProject)
```

### Toggling task completion:

```swift
task.toggleCompletion()
```

### Working with tags:

```swift
// Add a tag to a task
task.addTag(urgentTag)

// Or from the tag side
urgentTag.addToTask(task)
```

### Retrieving tasks:

```swift
// Get tasks due today
let todayTasks = context.tasks(dueOn: Date())

// Get all active tasks in a project
let activeTasks = project.activeTasks()

// Get overdue tasks
let overdueTasks = context.overdueTasks()
```
