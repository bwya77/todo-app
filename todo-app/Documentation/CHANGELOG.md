# Changelog

All notable changes to the Todo App will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

**Status**: Unreleased

## 2025-03-11

### Added
- Animated project completion indicator with smooth clockwise filling animation
- Project indicator added to Project Page and also animates as tasks are completed
- Modern rounded square checkboxes for tasks, replacing circular indicators
- Contextual checkbox coloring that matches project color or view type
- White checkmark symbol in completed task checkboxes for improved visibility

### Changed
- Project status indicators now animate smoothly between states
- Improved visual feedback when tasks are completed or added to projects
- Enhanced CoreData change detection for real-time UI updates
- Task completion now indicated with colored checkboxes instead of filled circles
- Completed task text now shows in light gray without strikethrough
- Improved checkbox visualization consistency across all task views (TaskRow, Calendar views)
- Enhanced visual feedback for task completion status
- Removed dividers between tasks in Projects page for a cleaner, more modern look
- Replaced SwiftUI List with custom ScrollView and LazyVStack implementation for better control over task appearance
- Enhanced task spacing and padding for improved readability without dividers
- Implemented custom disclosure groups in TaskListView to maintain collapsible functionality without dividers
- Enhanced context menu functionality for task deletion

### Fixed
- Project completion indicator now correctly calculates completion percentage
- Fixed project status circles not being project-specific in the Projects page like they were in the sidebar
- Ensured project status indicators update properly when moving between different projects
- Animation now works correctly for all transitions (0% to 100%, 100% to 0%, etc.)
- Resolved issue where adding new tasks didn't properly update completion indicators
- Fixed animation not playing when transitioning from partial to empty state
- Eliminated sidebar jitter when expanding from a collapsed state
- Replaced spring animation with smoother easeInOut for sidebar transitions
- Improved view hierarchy to stabilize sidebar position during transitions
- Enhanced content layout prioritization for smoother width adjustments
- Fixed emoji picker interaction with project title editing:
  - Resolved issue where inserting an emoji would immediately end editing
  - Fixed bug where clicking away from emoji picker without selecting an emoji would leave title in permanent editing state
  - Improved event handling for proper focus management during emoji insertion

## 2025-03-09

### Added
- Collapsible sidebar feature with toolbar toggle button
- NSToolbar integration for macOS native toolbar support
- Spring animations for smooth sidebar toggle experience
- State preservation for sidebar width when toggling visibility
- Unit tests for toolbar functionality in ToolbarDelegateTests.swift
- Comprehensive documentation for the sidebar toggle feature

### Changed
- Modified ContentView.swift to support conditional sidebar rendering
- Updated App.swift and AppDelegate.swift for improved toolbar and window management
- Enhanced README.md with new feature documentation
- Improved window appearance configuration for consistent toolbar visibility

### Fixed
- Sidebar animation now properly animates with spring physics for natural feel
- Toolbar no longer disappears when scrolling in sidebar or main content
- Window configuration now properly applies to new windows

### Technical Details
- Implemented proper NSToolbarDelegate pattern with singleton ToolbarDelegate
- Added utility extension for easy main window access (NSApplication.mainWindow)
- Configured proper toolbar item identifiers for sidebar toggle functionality
- Ensured compatibility with macOS Accessibility features through proper labeling
- Used SF Symbols "sidebar.left" and "sidebar.right" for toggle button states

### Development Notes
- Created comprehensive documentation in /Documentation/SidebarToggleFeature.md
- Modified NSScrollView behavior to preserve toolbar visibility during scrolling
- Implemented proper window notifications for consistent toolbar behavior
- Used SwiftUI's animation and transition system for smooth sidebar animation

## 2025-03-04

### Added
- Initial release of the Todo App
- Multiple calendar views (Day, Week, Month, Upcoming)
- Task management with project support
- Sidebar navigation with resizable width
- Real-time time indicators in Day and Week views
- Elegant animations for month/year transitions
- Core Data integration for persistent storage
