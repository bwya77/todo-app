# Project Headers Feature

## Overview
Project Headers allow users to organize tasks within projects into logical sections. Headers create visual separation and categorization without requiring tasks to be moved to separate projects.

## Implementation Details

### Data Model
- Created a new `ProjectHeader` entity in CoreData
- Added bidirectional relationships:
  - `Project` to `ProjectHeader` (one-to-many)
  - `ProjectHeader` to `Item` (one-to-many)
- Headers have display ordering to maintain consistent positioning

### UI Components
- `ProjectHeaderView`: Displays a header with edit/delete capabilities
- `HeaderTasksView`: Shows tasks belonging to a specific header
- `AddHeaderButton`: Allows creating new headers within a project

### Key Features
1. **Header Creation**: Users can add headers to any project
2. **Drag and Drop**: Tasks can be dragged between headers
3. **Reordering**: Both headers and tasks within headers can be reordered
4. **Editing**: Header titles can be edited inline
5. **Task Organization**: Tasks can belong to a header or remain unheadered

### Usage Flow
1. Create a project
2. Add headers to organize tasks (e.g., "Planning", "In Progress", "QA")
3. Create tasks directly under headers or drag existing tasks
4. Reorder headers to prioritize different sections

### Technical Notes
- Headers use a display order system similar to tasks and projects
- Drag and drop operations update both visual position and CoreData relationships
- Migration policy included to handle data model version upgrade

## Future Enhancements
- Color customization for individual headers
- Collapsible headers to focus on specific sections
- Header templates for quick project setup
- Keyboard shortcuts for header management
