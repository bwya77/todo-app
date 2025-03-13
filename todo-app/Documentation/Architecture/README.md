# Architecture Documentation

This section contains documentation related to the architecture and technical implementation of the Todo App.

## Contents

- [CoreData Optimizations](./CoreDataOptimizations.md) - Comprehensive guide to CoreData optimizations for improved performance
- [Fetch Request Improvements](./FetchRequestImprovements.md) - Detailed information about fetch request optimizations

## Overview

The Todo App follows a clean architecture pattern with clear separation of concerns:

1. **Domain Layer**: Contains the core business logic and entity definitions
2. **Infrastructure Layer**: Handles data persistence and technical implementations
3. **Presentation Layer**: Manages UI components and user interactions
4. **Application Layer**: Coordinates between the other layers

## Core Technologies

- **Swift**: The primary programming language
- **SwiftUI**: Used for UI components and views
- **CoreData**: Handles data persistence
- **Combine**: Used for reactive programming patterns

## Data Flow

1. User interactions are captured by SwiftUI views
2. Views communicate with ViewModels
3. ViewModels coordinate with repositories or services
4. Repositories interact with CoreData for persistence
5. Changes are published back to the UI via Combine publishers

## Performance Considerations

The app is designed with performance in mind, particularly for users with large numbers of tasks. Key optimizations include:

- Use of NSFetchedResultsController for efficient list management
- Batch fetching for calendar views
- Relationship prefetching to minimize faults
- Optimized predicates for common queries

For more detailed information about specific optimizations, refer to the CoreData Optimizations document.
