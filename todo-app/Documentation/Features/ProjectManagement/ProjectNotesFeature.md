# Project Notes Feature

## Overview
The Project Notes feature allows users to add free-form text notes to any project. These notes provide context, additional information, or reminders specific to a project. The notes field is designed to be subtle and unobtrusive, appearing as a light gray placeholder when empty, and displaying user input in the same font as the sidebar project name.

## Implementation Details

### Data Model Changes
- Added a new `notes` attribute to the `Project` entity in CoreData
- The attribute is optional and of type String
- Updated `Project+CoreDataExtensions.swift` to include notes in the creation and update methods

### UI Components
- Created a custom multi-line text editor (`ProjectNotesEditor.swift`) with the following features:
  - Transparent background with no border or outline
  - Light gray placeholder text ("Notes") when empty
  - Full width of the application
  - No visible scrollbars
  - Support for multiple lines of text using Shift+Enter
  - Font matching the sidebar project name

### User Experience
- When a project has no notes, a light gray "Notes" placeholder is shown
- When a user clicks on the field, the placeholder disappears and they can type notes
- Text is displayed in black font
- The text field maintains a clean, minimal appearance in line with the app's design
- Notes are stored per-project, ensuring each project can have its own notes
- Notes are automatically saved when the user types or navigates away

## Technical Implementation Highlights
- Uses custom `NSViewRepresentable` to wrap `NSTextView` for precise control
- Custom key handling to support Shift+Enter for new lines
- Automatic saving of notes to CoreData model
- Proper state management to ensure notes are loaded and saved correctly
- Clean integration with existing project detail view
- Font consistency with sidebar project name

## Future Enhancements
- Rich text formatting options
- Automatic linking of URLs, dates, and task references
- Search functionality within notes
- Markdown support
