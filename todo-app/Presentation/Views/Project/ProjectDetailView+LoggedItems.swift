//
//  ProjectDetailView+LoggedItems.swift
//  todo-app
//
//  Created on 3/19/25.
//

import SwiftUI

// Toggle component for project detail view
struct ProjectLoggedItemsToggle: View {
    @Binding var isExpanded: Bool
    let itemCount: Int
    
    var body: some View {
        Button(action: {
            withAnimation {
                isExpanded.toggle()
            }
        }) {
            HStack {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Text("Completed")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text("(\(itemCount))")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// Struct to allow animations only for logged items section
struct AnimatedLoggedSection<Content: View>: View {
    let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        content()
            // Only animate when items move between sections
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .move(edge: .bottom)),
                removal: .opacity.combined(with: .move(edge: .top))
            ))
    }
}

// Struct to disable animations for a section of content
struct AnimationDisabledSection<Content: View>: View {
    let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        content()
            .transaction { transaction in
                // Disable all animations within this section
                transaction.animation = nil
            }
    }
}
