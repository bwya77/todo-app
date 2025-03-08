# Components

This directory contains reusable UI components used throughout the application. These components should be designed to be generic and reusable across different parts of the app.

## Component Naming Conventions

Component files should be named according to their function without redundant suffixes:
- `[Name].swift` - e.g., TaskRow.swift, ProjectBadge.swift

## Implementation Notes

- Components should accept data and callbacks as parameters rather than directly accessing ViewModels or CoreData.
- Components should be designed with clear responsibilities and minimal state management.
- Styling should be consistent and follow the app's design system.

## Current Components

- `TaskRow.swift`: Displays a single task row with completion toggle functionality.

## Planned Components

- `ProjectBadge.swift`: Displays a project badge with appropriate color
- `PriorityIndicator.swift`: Shows the priority level of a task
- `CalendarCell.swift`: Reusable calendar day cell
- `CustomButton.swift`: Standardized button with consistent styling
- `DisclosureSection.swift`: Expandable/collapsible section
