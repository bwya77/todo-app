# Task Views with Drag-and-Drop Reordering

## Overview

This directory contains the various task list views for the Todo app, including the new reorderable task list implementation.

## View Types

1. **TaskListView** - Original implementation
2. **EnhancedTaskListView** - Improved implementation with NSFetchedResultsController
3. **ReorderableTaskListView** - Enhanced implementation with drag-and-drop reordering
4. **TaskListViewFactory** - Factory class to create the appropriate view based on feature flags

## Enabling/Disabling Reordering

Task reordering is controlled by a feature flag:

```swift
// In FeatureFlags.swift
static let enableTaskReordering = true
```

Set this to `false` to revert to the standard non-reorderable task list.

## Implementation Details

### Reorderable Components

The drag-and-drop functionality is provided by custom components:

- `ReorderableForEach`: A replacement for ForEach that supports drag reordering
- `ReorderableTaskSection`: A section view that uses ReorderableForEach
- `TaskReorderingViewModel`: Extensions to EnhancedTaskViewModel to handle reordering

### Data Persistence

When tasks are reordered:

1. The new order is saved to the CoreData model via the `displayOrder` attribute
2. Tasks are sorted primarily by `displayOrder` when the feature is enabled
3. New tasks are assigned an incremental order value

## Integration

The reorderable functionality is integrated at multiple levels:

1. UI Layer: Custom drag-and-drop components
2. View Model Layer: Methods for updating task order
3. Data Layer: CoreData model with displayOrder attribute
4. Fetch Layer: Queries that respect the display order

## Current Limitations

- Reordering between different sections/projects is not supported
- Visual feedback during dragging could be improved
- Mobile/touch support would require additional work
