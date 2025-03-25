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
    
    public init(area: Area, isSelected: Bool = false, isExpanded: Bool = true,
         onSelect: @escaping () -> Void = {}, onToggleExpand: @escaping () -> Void = {}) {
        self.area = area
        self.isSelected = isSelected
        self.isExpanded = isExpanded
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
                // Show active task count by default
                Text("\(area.activeTaskCount)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .opacity((isHoveringOver || isHoveringRow) ? 0 : 1)
                
                // Show expand/collapse control on hover
                Button(action: {
                    onToggleExpand()
                }) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                .buttonStyle(PlainButtonStyle())
                .opacity((isHoveringOver || isHoveringRow) ? 1 : 0)
            }
            .frame(width: 20)
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
