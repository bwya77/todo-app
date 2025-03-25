# Sidebar Expand/Collapse Enhancement

## Overview

This enhancement improves the user experience in the sidebar by showing expand/collapse icons for areas whenever the mouse is hovering anywhere within the sidebar. Previously, expand/collapse icons would only appear when hovering directly over an individual area row.

## Implementation Details

### Sidebar Hover State Implementation

We've implemented a simple and direct approach to track when the mouse is hovering over the sidebar. This approach has several advantages:

1. **Simple State Management**: Uses SwiftUI's built-in state management
2. **Efficient Updates**: Only updates the UI when the hover state actually changes
3. **Direct Propagation**: Passes hover state directly to child components 

The implementation uses a local state variable in the SidebarView that is passed down to child components:

```swift
// In SidebarView
@State private var isSidebarHovered: Bool = false

// Add hover detection to the entire sidebar
.onHover { isHovered in
    withAnimation(.easeInOut(duration: 0.15)) {
        isSidebarHovered = isHovered
    }
}
```

### Area Row Component Changes

The `AreaRowView` component has been updated to accept the sidebar hover state as a parameter and show expand/collapse icons accordingly:

```swift
// Receive sidebar hover state from parent
var isSidebarHovered: Bool = false

// Show task count with opacity based on hover state
Text("\(area.activeTaskCount)")
    // ...
    .opacity((isHoveringOver || isHoveringRow || isSidebarHovered) ? 0 : 1)

// Show expand/collapse button based on hover state
Button(action: { onToggleExpand() }) {
    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
    // ...
}
.buttonStyle(PlainButtonStyle())
.opacity(isExpanded || area.activeTaskCount == 0 || isSidebarHovered || (isHoveringOver || isHoveringRow) ? 1 : 0)
```

### Sidebar Hover Detection

The sidebar hover detection is applied directly in the `SidebarView` with a simple `onHover` modifier:

```swift
// In SidebarView body
.onHover { isHovered in
    withAnimation(.easeInOut(duration: 0.15)) {
        isSidebarHovered = isHovered
    }
}
```

This hover state is then passed to the `ReorderableProjectList` component, which in turn passes it to each `AreaRowView`:

```swift
// In SidebarView
ReorderableProjectList(
    selectedViewType: $selectedViewType,
    selectedProject: $selectedProject,
    selectedArea: $selectedArea,
    isSidebarHovered: isSidebarHovered
)

// In ReorderableProjectList renderAreaRow method
AreaRowView(
    area: area,
    isSelected: selectedViewType == .area && selectedArea?.id == area.id,
    isExpanded: isExpanded,
    isSidebarHovered: isSidebarHovered,
    // ... other parameters
)
```

## User Experience Benefits

This enhancement provides several key improvements to the user experience:

1. **Discoverability**: Users can more easily discover that areas are expandable/collapsible
2. **Efficiency**: Users can quickly see and interact with expand/collapse controls without needing to precisely hover over each area
3. **Consistency**: The UI feels more responsive and consistent by providing visual feedback as soon as the user's mouse enters the sidebar
4. **Reduced Precision Requirements**: Users no longer need to precisely hover over a specific small target to reveal expand/collapse controls

## Testing

The feature has been tested in various scenarios:

- Mouse entering/leaving the sidebar
- Interaction with areas that have tasks vs. no tasks
- Areas in expanded vs. collapsed states
- Performance impact of the global state updates

## Accessibility Considerations

The expand/collapse buttons maintain their accessibility labels:

```swift
.accessibilityLabel(Text(isExpanded ? "Collapse Area" : "Expand Area"))
```

This ensures that screen readers correctly announce the purpose of these controls.
