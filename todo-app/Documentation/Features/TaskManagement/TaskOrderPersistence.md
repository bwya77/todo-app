# Task Order Persistence Feature

## Overview

This feature ensures that when users reorder tasks in projects, Inbox, Today, or Completed views, their order is preserved and restored whenever the application is launched.

## Implementation Details

### Core Components

1. **Task Display Order**
   - Each task has a `displayOrder` attribute in CoreData that stores its position
   - Tasks are sorted primarily by this attribute in all views
   - We use 10-point spacing between values (0, 10, 20, 30...) to allow easy insertion

2. **AppLaunchTaskOrderInitializer**
   - Singleton class that runs at app launch
   - Ensures every task has a valid `displayOrder` attribute
   - Verifies ordering consistency and repairs if needed

3. **PersistentOrder Class**
   - Enhanced reliability for saving CoreData changes
   - Forces WAL checkpointing and disk synchronization
   - Prevents data loss during app termination or unexpected crashes

4. **Save Order Observers**
   - `SaveOrderObserver`: View modifier for individual views
   - `SaveOrderOnNavigationModifier`: App-wide modifier for persistent ordering
   - Responds to `TaskOrderChanged` notifications

5. **Item+OrderingExtensions**
   - Core reordering logic implemented in `reorderTasks` static method
   - Provides utility methods for getting ordered tasks

### Key Features

- **Reliability**: Multiple layers of save mechanisms ensure data persistence
- **Performance**: Optimized save operations to prevent excessive disk writes
- **Debugging**: Comprehensive logging and task order validation
- **Recovery**: Tools to repair ordering if corruption occurs

### Execution Flow

1. At app launch, `AppLaunchTaskOrderInitializer` runs to ensure valid ordering
2. When user drags to reorder tasks:
   - `ReorderableForEach` updates the array order in memory
   - `reorderTasks` method applies new `displayOrder` values and saves
   - `TaskOrderChanged` notification triggers persistence
3. When navigating away or closing app:
   - `onDisappear` triggers final save
   - `applicationWillTerminate` ensures final flush to disk

## Best Practices

- Using 10-point spacing for insertion flexibility
- Sorting by `displayOrder` first, then fallback to other attributes
- Comprehensive error handling and logging
- Multiple save points to prevent data loss

## Future Improvements

- Consider batch updates for large collections to improve performance
- Add conflict resolution for multiple window scenarios
- Implement undo/redo for reordering operations
