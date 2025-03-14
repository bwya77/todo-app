# Project Notes Feature Implementation

## Overview

This document details the implementation of the Project Notes feature, which allows users to add multi-line text notes to projects in the Todo App. The feature provides a clean, minimal interface that expands as content is added.

## Requirements

1. Add a multi-line text input field to the Project detail view
2. Text field should have no visible border or background (transparent)
3. When empty, display a light gray "Notes" placeholder
4. By default, show as a single line but expand as content grows or when Enter is pressed
5. Push other content down when expanding (not scroll up)
6. Notes should be project-specific and persist with CoreData
7. Text should match the sidebar project name font
8. No visible scrollbars

## Implementation Steps

### 1. CoreData Model Update

The first step was extending the `Project` entity in CoreData:

```swift
// Added 'notes' attribute to Project entity
<entity name="Project" representedClassName="Project" syncable="YES" codeGenerationType="class">
    <attribute name="color" attributeType="String" defaultValueString="gray"/>
    <attribute name="id" attributeType="UUID" usesScalarValueType="NO"/>
    <attribute name="name" attributeType="String" defaultValueString="Untitled Project"/>
    <attribute name="notes" optional="YES" attributeType="String"/>
    <relationship name="items" optional="YES" toMany="YES" deletionRule="Cascade" destinationEntity="Item" inverseName="project" inverseEntity="Item"/>
    <uniquenessConstraints>
        <uniquenessConstraint>
            <constraint value="id"/>
        </uniquenessConstraint>
    </uniquenessConstraints>
</entity>
```

### 2. TaskViewModel Update

Enhanced the TaskViewModel to support updating project notes:

```swift
func updateProject(_ project: Project, name: String? = nil, color: String? = nil, notes: String? = nil) {
    if let name = name {
        project.name = name
    }
    if let color = color {
        project.color = color
    }
    if let notes = notes {
        project.notes = notes
    }
    
    saveContext()
}
```

### 3. Custom Text Editor Component

Created a custom SwiftUI wrapper around NSTextView for precise control:

```swift
struct ProjectNotesEditor: View {
    @Binding var text: String
    let placeholder: String
    let font: Font
    
    @FocusState private var isFocused: Bool
    private let defaultLineHeight: CGFloat = 22
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Placeholder text when empty
            if text.isEmpty && !isFocused {
                Text(placeholder)
                    .font(font)
                    .foregroundColor(Color.gray.opacity(0.5))
                    .allowsHitTesting(false)
                    .padding(.horizontal, 2)
                    .padding(.top, 2)
                    .zIndex(1)
            }
            
            // Text editor that grows downward
            TextEditorWithShiftEnter(text: $text, font: font)
                .focused($isFocused)
                .frame(height: calculateHeight())
                .foregroundColor(.black)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }
    
    // Height calculation based on content
    private func calculateHeight() -> CGFloat {
        // Calculate height based on line count and content length
        let lineCount = text.components(separatedBy: "\n").count
        let wrappedLineEstimate = text.count / 80
        let totalLines = max(lineCount, wrappedLineEstimate + 1)
        let calculatedHeight = CGFloat(totalLines) * defaultLineHeight
        
        // Cap at 5 lines maximum height
        return min(max(defaultLineHeight, calculatedHeight), defaultLineHeight * 5)
    }
}
```

### 4. NSViewRepresentable for Text Editor

Created a custom NSViewRepresentable to wrap NSTextView for Shift+Enter handling:

```swift
struct TextEditorWithShiftEnter: NSViewRepresentable {
    @Binding var text: String
    var font: Font
    
    func makeNSView(context: Context) -> NSScrollView {
        // Setup scroll view and text view with proper configuration for downward expansion
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .noBorder
        scrollView.backgroundColor = NSColor.clear
        
        let textView = NSTextView(frame: scrollView.bounds)
        textView.delegate = context.coordinator
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        // ... more configuration ...
        
        // Custom Shift+Enter handling in the coordinator
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) { /* ... */ }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        // Custom handling of Enter key to add new lines
        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                // Insert a new line directly
                textView.insertText("\n", replacementRange: textView.selectedRange)
                return true
            }
            return false
        }
        // ... other delegate methods ...
    }
}
```

### 5. Integration with ProjectDetailView

Integrated the notes editor into the ProjectDetailView with a direct binding to the CoreData model:

```swift
// Project Notes - Directly binding to project.notes property
ProjectNotesEditor(
    text: Binding(
        get: { self.project.notes ?? "" },
        set: { newValue in
            self.project.notes = newValue
            do {
                try self.viewContext.save()
            } catch {
                print("Error saving project notes: \(error)")
            }
        }
    ),
    placeholder: "Notes", 
    font: .system(size: 14, weight: .regular)
)
.padding(.horizontal, 16)
.padding(.vertical, 8)
// Force complete recreation when project changes
.id("project-notes-editor-\(self.project.id?.uuidString ?? UUID().uuidString)")
```

### 6. View Identity Management

To ensure notes remain project-specific, added unique identifiers:

```swift
.id("project-detail-view-\(project.id?.uuidString ?? UUID().uuidString)")
```

This forces SwiftUI to create an entirely new view instance when switching between projects.

## Challenges and Solutions

### Challenge 1: Project-Specific Notes

Initially, notes were being shared between projects. This was fixed by:

1. Using a direct binding to the project.notes property
2. Adding unique identifiers to the view hierarchy
3. Ensuring proper CoreData updates

### Challenge 2: Downward Expansion

Text was initially shifting upward when adding new lines. Fixed by:

1. Using `.fixedSize(horizontal: false, vertical: true)` to force proper growth
2. Setting correct NSTextView configurations for vertical expansion
3. Implementing a custom height calculation algorithm

### Challenge 3: Persistence

Notes would sometimes disappear when navigating away. Fixed by:

1. Creating a direct CoreData binding
2. Saving immediately on text changes
3. Ensuring proper view recreation when switching projects

## Final Implementation

The implementation provides a clean, minimal notes editor that:
- Starts as a single line
- Expands downward as content grows without limits
- Shows a placeholder when empty
- Has no visible borders or scrollbars
- Correctly saves notes per project
- Supports Enter key for new lines

The feature enhances project management by allowing users to add context, details, and reminders specific to each project without cluttering the interface.
