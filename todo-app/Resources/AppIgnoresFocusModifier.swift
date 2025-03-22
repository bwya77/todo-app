//
//  AppIgnoresFocusModifier.swift
//  todo-app
//
//  Created on 3/22/25.
//

import SwiftUI

// Custom view modifier to ignore app inactive state
struct IgnoreAppInactiveModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .colorScheme(colorScheme) // Preserve color scheme
            .preferredColorScheme(colorScheme) // Enforce color scheme
            .foregroundStyle(.primary) // Keep text colors consistent
    }
}

// Extension to make it easy to apply this to any view
extension View {
    func ignoreAppInactiveState() -> some View {
        self.modifier(IgnoreAppInactiveModifier())
    }
}

// Custom button style that maintains appearance when app loses focus
struct ConsistentButtonStyle: ButtonStyle {
    let backgroundColor: Color
    let textColor: Color
    let isSelected: Bool
    
    init(backgroundColor: Color = .clear, 
         textColor: Color = .primary,
         isSelected: Bool = false) {
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.isSelected = isSelected
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(textColor)
            .background(
                backgroundColor
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .cornerRadius(4)
            // Important: this prevents macOS from changing the button appearance when the app loses focus
            .environment(\.isEnabled, true)
    }
}
