# Implement Collapsible Sidebar with Toolbar Toggle

## Description
This PR implements a collapsible sidebar feature with a toolbar toggle button positioned in the window's title bar, to the right of the traffic light controls. The implementation follows macOS design patterns and best practices for native-feeling integration.

## Features
- Added a toolbar button to show/hide the sidebar
- Implemented smooth animations for sidebar collapsing/expanding
- Maintained sidebar width when toggling visibility
- Ensured proper toolbar visibility and behavior
- Added comprehensive documentation and unit tests

## Technical Implementation
### NSToolbar Integration
- Created a `ToolbarDelegate` class to handle toolbar configuration and actions
- Integrated toolbar button with SwiftUI state management
- Added proper SF Symbols ("sidebar.left" and "sidebar.right") for toggle states

### Animation & Transitions
- Implemented spring physics for natural sidebar toggle animation
- Used SwiftUI's `.transition(.move(edge: .leading))` for sidebar sliding effect
- Added opacity transition for the resize handle

### Window Configuration
- Enhanced AppDelegate to properly configure window appearance
- Added window notification observers to maintain consistent toolbar state
- Set proper toolbar style for macOS integration

### Performance & Architecture
- Used singleton pattern for ToolbarDelegate to ensure consistent state
- Implemented proper binding between NSToolbar and SwiftUI
- Ensured animations perform well and main content updates correctly

## Documentation
- Added comprehensive documentation in `/Documentation/SidebarToggleFeature.md`
- Updated the README.md with new feature information
- Created a CHANGELOG.md to track changes
- Added PR templates for future development

## Testing
- Added unit tests for ToolbarDelegate functionality
- Manually tested on various window sizes
- Verified smooth animation performance
- Tested toolbar visibility across application states

## Screenshots
[Screenshots would be placed here in a real PR]

## Future Improvements
- Add keyboard shortcut support (⌘+/)
- Consider adding customization options for sidebar width
- Explore adding a persistent preference for sidebar state

