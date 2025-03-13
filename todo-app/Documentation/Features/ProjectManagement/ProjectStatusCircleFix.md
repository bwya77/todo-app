# Project Status Circle Fix

## Issue
In the Projects page, the project status circles (indicators) to the left of the project titles were not project-specific. When checking a task off in one project and the status circle changed to show its completion, going to another project would show the same status indicator, even though the second project's tasks were not completed. This differed from the sidebar behavior where the indicators were correctly project-specific.

## Root Cause
The problem was related to how the `ProjectCompletionIndicator` component was implemented and used in different views:

1. In the sidebar, the indicator was correctly associated with each specific project
2. In the Projects page views (`TaskListView` and `ProjectDetailView`), the indicators weren't properly refreshing when projects changed or tasks were completed in different projects
3. The underlying `ProjectCompletionTracker` wasn't explicitly handling project changes

## Solution
The following changes were implemented to fix the issue:

### 1. Enhanced `ProjectCompletionIndicator`
- Added a more robust ID to ensure the view refreshes properly when projects change
- Updated the `onChange` method to properly handle project changes and update the completion tracker
- Added unique identifiers for each indicator instance to force view recreation when moving between projects

### 2. Improved `ProjectCompletionTracker`
- Added an `updateProject` method to explicitly handle changes in the tracked project
- Ensured the tracker refreshes data when the project changes
- Improved the updating mechanism for completion percentage

### 3. Updated Views Using the Indicators
- Added explicit unique IDs in `ProjectDetailView`, `TaskListView`, and `SidebarView` to ensure each indicator instance is properly recreated when projects change
- Used the project ID in ID generation to ensure each indicator stays connected to its specific project
- Enhanced the indicator response to project and task changes

## Technical Details

### ProjectCompletionIndicator Changes
```swift
// Use a unique ID based on the project ID to force recreation when project changes
.id("progress-\(project.id?.uuidString ?? UUID().uuidString)")

// Added onChange handler to properly update when project changes
.onChange(of: project) { oldProject, newProject in
    if oldProject.id != newProject.id {
        tracker.updateProject(newProject.id)
        animator.reset()
        animator.animateTo(tracker.completionPercentage)
    } else {
        // The project is the same but might have been updated
        tracker.refresh()
        animator.animateTo(tracker.completionPercentage)
    }
}
```

### ProjectCompletionTracker Changes
```swift
/// Update the project ID being tracked
/// - Parameter projectId: The new project ID to track
func updateProject(_ projectId: UUID?) {
    // Only update if the ID is different
    if self.projectId != projectId {
        self.projectId = projectId
        updateCompletionPercentage()
    }
}
```

### View-level Changes
In `ProjectDetailView`, `TaskListView`, and `SidebarView`, added unique IDs to each indicator:

```swift
ProjectCompletionIndicator(
    project: project,
    size: 20,
    viewContext: viewContext
)
// Add a unique ID for this instance to force recreation when project changes
.id("view-indicator-\(project.id?.uuidString ?? UUID().uuidString)")
```

## Results
After implementing these changes, the project status circles now correctly:
1. Show project-specific completion states for each individual project
2. Update in real-time when tasks are completed or added
3. Maintain their correct state when navigating between different projects
4. Share the same behavior between the sidebar and Projects page

The fix ensures consistency in the app's UI and provides users with accurate visual feedback about project completion status.
