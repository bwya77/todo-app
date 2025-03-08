# ViewModels

This directory contains the ViewModels used by the application. ViewModels serve as the intermediary between the domain layer and the UI layer, providing the necessary data and operations to the views.

## ViewModel Naming Conventions

All ViewModels should follow the naming convention:
- `[Name]ViewModel.swift` - e.g., TaskViewModel.swift, CalendarViewModel.swift

## Implementation Notes

- ViewModels should be implemented as ObservableObject to enable SwiftUI data binding.
- State management should happen in the ViewModel, not in the View.
- ViewModels should not directly depend on CoreData entities, but work through repositories and domain models.
- Business logic should be in the domain layer (Services/UseCases), not in ViewModels.

## Current ViewModels

- `TaskViewModel.swift`: Provides task management functionality for views

## Planned ViewModels

- `CalendarViewModel.swift`: Provides calendar data and operations for calendar views
- `ProjectViewModel.swift`: Provides project management functionality
- `TaskListViewModel.swift`: Provides specific operations for task lists
- `SettingsViewModel.swift`: Manages application settings
