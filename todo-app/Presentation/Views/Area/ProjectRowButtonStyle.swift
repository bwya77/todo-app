//
//  ProjectRowButtonStyle.swift
//  todo-app
//
//  Created on 3/25/25.
//

import SwiftUI

/// Custom button style for project rows in the area detail view
struct ProjectRowButtonStyle: ButtonStyle {
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.gray.opacity(0.1) : Color.clear)
            )
            .contentShape(Rectangle())
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    self.isHovered = hovering
                }
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == ProjectRowButtonStyle {
    static var projectRow: ProjectRowButtonStyle { ProjectRowButtonStyle() }
}
