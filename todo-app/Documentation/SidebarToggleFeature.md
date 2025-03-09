# Sidebar Toggle Feature Documentation

## Overview

The Sidebar Toggle feature adds a button to the macOS toolbar that allows users to show or hide the sidebar with a smooth animation. When hidden, the main content area expands to use the full width of the window, providing more space for the task list or calendar views.

## Implementation Details

### Architecture

The feature follows Apple's recommended patterns for macOS toolbar integration:

1. **NSToolbar Integration**: We use native NSToolbar and NSToolbarItem classes to add a toggle button to the title bar.
2. **Animation**: SwiftUI's animation system provides smooth transitions when showing or hiding the sidebar.
3. **State Management**: We use a combination of SwiftUI's `@State` property wrapper and callbacks to maintain the sidebar visibility state.

### Core Components

#### ToolbarDelegate

The `ToolbarDelegate` class implements the `NSToolbarDelegate` protocol and handles toolbar configuration and item creation. Key features:

- Singleton instance accessible via `ToolbarDelegate.shared`
- Maintains a binding to the sidebar visibility state
- Creates and configures the toolbar item with appropriate icon and action
- Handles the toggle action to show/hide the sidebar

```swift
// From ContentView.swift
class ToolbarDelegate: NSObject, NSToolbarDelegate {
    static let shared = ToolbarDelegate()
    
    // Toolbar item identifiers
    private let toggleSidebarItemID = NSToolbarItem.Identifier("toggleSidebar")
    
    // Binding to update sidebar visibility
    var sidebarVisibilityBinding: Binding<Bool>? = nil
    
    // Implementation details...
}
```

#### ContentView Sidebar Toggle Integration

The ContentView implements sidebar visibility toggling using:

- `@State private var isSidebarVisible: Bool = true` to track sidebar state
- SwiftUI's `if isSidebarVisible {...}` conditional rendering
- `.transition(.move(edge: .leading))` for smooth animation
- `.animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSidebarVisible)` for natural animation feel

#### Toolbar Setup

The toolbar is set up in the ContentView's `setupToolbar()` method which:

1. Gets a reference to the main window
2. Creates a toolbar with the identifier "MainWindowToolbar"
3. Assigns the ToolbarDelegate as the toolbar's delegate
4. Ensures the toolbar remains visible
5. Sets up a binding to the sidebar visibility state

## Usage

The sidebar toggle is automatically available in the title bar, to the right of the traffic light buttons. Users can:

1. Click to collapse the sidebar, expanding the main content area to full width
2. Click again to restore the sidebar to its previous width
3. Resize the sidebar using the resize handle when visible

## Extensions

The feature includes the following helper extensions:

### NSApplication Extension

```swift
extension NSApplication {
    var mainWindow: NSWindow? {
        return windows.first { $0.isKeyWindow } ?? windows.first
    }
}
```
This extension provides a clean way to access the main window of the application.

## Testing

Unit tests for the toolbar functionality are provided in `ToolbarDelegateTests.swift`, which include:

- Testing the creation of the toggle sidebar item
- Ensuring the toolbar's default and allowed items are correctly configured
- Testing the main window extension

## Styling Notes

The sidebar toggle button uses Apple's SF Symbols:
- "sidebar.left" for the action to hide the sidebar
- "sidebar.right" for the action to show the sidebar

This follows Apple's HIG guidelines for sidebar controls on macOS.

## Performance Considerations

- **Animation** - We use spring animation with carefully tuned parameters for smooth transitions.
- **View Reconstruction** - When the sidebar is toggled, the main content does not reload or redraw.
- **Native Integration** - By using NSToolbar, we achieve native macOS integration with minimal overhead.

## Accessibility

The sidebar toggle button includes:
- Proper labels and tooltips for screen readers
- Keyboard accessibility through standard macOS toolbar keyboard navigation
- A clear visual indicator of the current state (show/hide sidebar)
