# Sidebar Toggle Button Hover Effect

## Overview
The Sidebar Toggle Button in the todo app now has enhanced interactivity with hover and click effects. When users hover over the sidebar toggle button, the button shows a light grey rounded square background. When clicked, the background becomes slightly darker until the click is released.

## Implementation Details

### Button Design
- The sidebar toggle button uses a `SidebarToggleButton` SwiftUI view inside an `NSHostingView`
- The button has three visual states:
  - Default: Icon with no background
  - Hover: Icon with a light grey rounded square background (`AppColors.sidebarHover`)
  - Pressed: Icon with a slightly darker grey background (`AppColors.sidebarHover.opacity(0.8)`)
- The toggle functionality remains the same: clicking shows/hides the sidebar and updates the icon

### Technical Implementation
- Created a custom `SidebarToggleButton` view in ContentView.swift
- Used `.onHover` modifier to detect mouse hover events
- Used `.simultaneousGesture` with `DragGesture` to detect press state
- Animated state transitions using `.animation(.easeInOut(duration: 0.1))`
- Replaced the NSToolbarItem's image with an NSHostingView containing the custom SwiftUI button

### Testing
- Added unit tests in `SidebarIconTests.swift` to verify the button states
- Added additional tests in `SidebarAnimationTests.swift` for hover and click behavior

## Usage
The sidebar toggle button appears in the application toolbar. Users can:
1. Hover over the button to see a visual highlight
2. Click the button to toggle the sidebar visibility
3. When clicked, the button darkens until released

## Benefits
- Improved user feedback through visual interaction cues
- Consistent with modern macOS interface design guidelines
- Provides clearer indication of clickable areas in the interface
- Matches the UI pattern used elsewhere in the application

## Related Features
- Sidebar visibility toggle (existing functionality)
- Sidebar animation for show/hide transitions

## Future Enhancements
- Consider extending similar hover/click effects to other toolbar buttons
- Fine-tune the hover/click colors based on user feedback and macOS appearance modes
