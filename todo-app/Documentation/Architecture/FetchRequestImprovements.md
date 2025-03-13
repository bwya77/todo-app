# Fetch Request Improvements

This document outlines the improvements made to the Todo app's data fetching system to enhance performance and maintainability.

## 1. NSFetchedResultsController Implementation

The `TaskFetchedResultsController` class has been implemented to leverage CoreData's native `NSFetchedResultsController` for improved list management. This provides several benefits:

- **Automatic Updates**: Changes to the CoreData store are automatically reflected in the UI without manual refreshing
- **Memory Efficiency**: Only fetches objects that are currently needed for display
- **Section Support**: Provides built-in support for sectioned data with minimal overhead
- **Reduced Boilerplate**: Centralizes change tracking and notification logic

Key features of our implementation:
- Uses Combine to publish changes to subscribers
- Handles section management for grouped views
- Provides clean API for UI components

## 2. Batch Fetching for Calendar Views

Calendar views can potentially display many tasks at once. To optimize performance, we've implemented:

- **Optimized Batch Size**: Configured fetch requests with appropriate batch sizes for different views
- **Relationship Prefetching**: Prefetches related entities (like projects) to avoid subsequent faults
- **Date Range Optimization**: Special fetch request methods for calendar month/week views

These optimizations ensure smooth scrolling and responsiveness when navigating calendar views with many tasks.

## 3. Dedicated Fetch Request Factories

The `TaskFetchRequestFactory` has been enhanced with:

- **Comprehensive Fetch Methods**: Specialized methods for common query patterns (today, by project, by date, etc.)
- **Sorting Consistency**: Standard sort descriptors ensure consistent ordering across the app
- **Predicate Optimization**: Well-structured predicates for optimal query performance
- **Calendar-specific Methods**: Optimized requests for calendar views with appropriate batch sizes

## 4. Enhanced ViewModels

New ViewModels have been created to leverage these improvements:

- **EnhancedTaskViewModel**: Uses NSFetchedResultsController for general task lists
- **CalendarTaskViewModel**: Specialized for calendar views with batch fetching optimization

These ViewModels provide a clean, consistent API for views while internally leveraging the optimized fetch mechanisms.

## 5. Performance Benefits

These improvements provide significant performance benefits:

- **Reduced Memory Usage**: Only objects currently in view are fully faulted into memory
- **Faster Initial Load**: By batching fetches, initial view loading is much quicker
- **Smoother Scrolling**: Batch fetching prevents UI hitches when scrolling through long lists
- **More Responsive UI**: Changes are reflected immediately through the NSFetchedResultsController
- **Lower CPU Usage**: Fewer fetches and better management of faulting reduces CPU load

## 6. Code Organization and Maintainability

- **Separation of Concerns**: Fetch logic is now separated from UI logic
- **Centralized Fetch Logic**: Common fetch patterns are consolidated in the factory
- **Consistent Query Patterns**: Standard approaches for common operations
- **Reduced Duplication**: No more repetitive fetch request setup throughout the app
- **Better Testability**: The factory methods and controllers can be tested independently

## Usage Examples

### Using the NSFetchedResultsController

```swift
// Initialize the controller for a specific view type
let controller = TaskFetchedResultsController(
    viewType: .today, 
    context: viewContext
)

// Subscribe to updates
controller.tasksPublisher
    .sink { tasks in
        // Update UI with new tasks
    }
    .store(in: &cancellables)
```

### Using Batch Fetching for Calendar

```swift
// Fetch tasks for a month with optimized batch fetching
let request = TaskFetchRequestFactory.calendarMonthTasks(
    from: startDate, 
    to: endDate, 
    in: context
)

// The request is configured with:
// - Appropriate batch size
// - Relationship prefetching
// - Optimized predicates
```
