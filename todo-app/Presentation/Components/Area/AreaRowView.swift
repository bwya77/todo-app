//
//  AreaRowView.swift
//  todo-app
//
//  Created on 3/22/25.
//

import SwiftUI
import CoreData

/// Row view for areas in the sidebar with hover-based expand/collapse controls
public struct AreaRowView: View {
    let area: Area
    let isSelected: Bool
    let isExpanded: Bool
    var onSelect: () -> Void
    var onToggleExpand: () -> Void
    
    @State private var isHoveringOver: Bool = false
    @State private var isHoveringRow: Bool = false
    
    // Receive sidebar hover state from parent
    var isSidebarHovered: Bool = false
    
    public init(area: Area, isSelected: Bool = false, isExpanded: Bool = true,
         isSidebarHovered: Bool = false,
         onSelect: @escaping () -> Void = {}, onToggleExpand: @escaping () -> Void = {}) {
        self.area = area
        self.isSelected = isSelected
        self.isExpanded = isExpanded
        self.isSidebarHovered = isSidebarHovered
        self.onSelect = onSelect
        self.onToggleExpand = onToggleExpand
    }
    
    public var body: some View {
        HStack(spacing: 10) {
            // Main area content (name, icon, etc.)
            HStack(spacing: 10) {
                // Area icon
                Image(systemName: isExpanded ? "cube" : "shippingbox.fill")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.getColor(from: area.color ?? "gray"))
                
                // Area name
                Text(area.name ?? "Unnamed Area")
                    .lineLimit(1)
                    .foregroundStyle(isSelected ? AppColors.selectedTextColor : .black)
                    .font(.system(size: 14, weight: .bold))
                
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onSelect()
            }
            
            // Task count / expand-collapse control with hover effect
            ZStack {
                // Show active task count by default, only when we have tasks and area is not expanded
                if area.activeTaskCount > 0 && !isExpanded {
                    Text("\(area.activeTaskCount)")
                        .font(.system(size: 14)) // Match project task count size
                        .foregroundColor(.secondary)
                        .frame(width: 20, alignment: .trailing) // Ensure consistent width and alignment
                        .opacity((isHoveringOver || isHoveringRow || isSidebarHovered) ? 0 : 1)
                }
                
                // Show expand/collapse control based on state:
                // - Always visible if area is expanded
                // - Always visible if area has 0 tasks
                // - Visible when sidebar is hovered
                // - Visible on this specific row hover
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
                .opacity(isExpanded || area.activeTaskCount == 0 || isSidebarHovered || (isHoveringOver || isHoveringRow) ? 1 : 0)
            }
            .frame(width: 20, alignment: .trailing) // Match project task count alignment
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHoveringOver = hovering
                }
                
                if hovering {
                    NSCursor.pointingHand.set()
                } else {
                    NSCursor.arrow.set()
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isSelected 
                      ? AppColors.lightenColor(AppColors.getColor(from: area.color ?? "blue"), by: 0.7)
                      : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHoveringRow = hovering
            }
        }
    }
}
