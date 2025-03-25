# Feature Change Log - Sidebar Area Icons Enhancement

Date: March 25, 2025
Developer: Senior macOS Developer

## Overview
Enhanced the sidebar area icons to provide cleaner, more intuitive user experience based on state.

## Requirements Implemented
1. If the area is expanded, only show the collapse icon (not the task count)
2. If an area has 0 outstanding project tasks, just show the Expand/Collapse icon (not the task count)
3. Fixed alignment issues between area task counts and project task counts for consistent visual appearance

## Files Modified
1. `/Users/bradley.wyatt/Git/GitHub/todo-app/todo-app/Presentation/Components/Area/AreaRowView.swift`
   - Changed the ZStack logic for task count and expand/collapse button
   - Added accessibility labels for better testing and accessibility

## Files Added
1. `/Users/bradley.wyatt/Git/GitHub/todo-app/todo-app/Documentation/Features/UI/SidebarAreaIconImprovements.md`
   - Added detailed documentation about the new feature
   - Included code samples and rationale for the changes

2. `/Users/bradley.wyatt/Git/GitHub/todo-app/todo-appTests/SidebarAreaIconTests.swift`
   - Created unit tests for the new feature
   - Tests verify the three key behaviors:
     - Expanded areas only show collapse icon
     - Areas with 0 tasks only show expand/collapse icon
     - Collapsed areas with tasks show count by default

3. `/Users/bradley.wyatt/Git/GitHub/todo-app/todo-appTests/ViewInspectorExtensions.swift`
   - Added testing infrastructure for UI components

## Implementation Details
The key implementation is in `AreaRowView.swift` where we added conditional logic and alignment fixes:

```swift
// Task count / expand-collapse control with hover effect
ZStack {
    // Show active task count by default, only when we have tasks and area is not expanded
    if area.activeTaskCount > 0 && !isExpanded {
        Text("\(area.activeTaskCount)")
            .font(.system(size: 14)) // Match project task count size
            .foregroundColor(.secondary)
            .frame(width: 20, alignment: .trailing) // Ensure consistent width and alignment
            .opacity((isHoveringOver || isHoveringRow) ? 0 : 1)
    }
    
    // Show expand/collapse control based on state:
    // - Always visible if area is expanded
    // - Always visible if area has 0 tasks
    // - Visible on hover otherwise
    Button(action: {
        onToggleExpand()
    }) {
        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
            .font(.system(size: 12))
            .foregroundColor(.gray)
            .accessibilityLabel(Text(isExpanded ? "Collapse Area" : "Expand Area"))
            .frame(width: 20, alignment: .trailing) // Consistent alignment with count
    }
    .buttonStyle(PlainButtonStyle())
    .opacity(isExpanded || area.activeTaskCount == 0 || (isHoveringOver || isHoveringRow) ? 1 : 0)
}
.frame(width: 20, alignment: .trailing) // Match project task count alignment
```

## Testing
Added tests to verify all three behaviors. To run the tests:
1. Open the project in Xcode
2. Select the SidebarAreaIconTests test class
3. Run the tests (Product > Test or Cmd+U)

All tests should pass, confirming the feature works as expected.

## Benefits
1. **Reduced Visual Clutter**: By showing only the most relevant information in each state
2. **Intuitive Interaction**: Users can clearly understand what actions are available based on context
3. **Consistent Experience**: Follows UI patterns familiar to users of modern macOS applications
4. **Better Information Hierarchy**: Prioritizes showing task counts only when meaningful

## Future Considerations
- Adding animation to smooth transitions between task count and expand/collapse icon
- Handling very large task counts with condensed numbering (e.g., 99+)
- Further accessibility improvements
