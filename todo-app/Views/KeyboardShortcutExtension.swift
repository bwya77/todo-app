//
//  KeyboardShortcutExtension.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/6/25.
//

import SwiftUI

// Extension to handle keyboard shortcuts
extension View {
    func onKeyboardShortcut(_ key: KeyEquivalent, modifiers: EventModifiers = [], action: @escaping () -> Void) -> some View {
        self.keyboardShortcut(key, modifiers: modifiers)
            .onAction {
                action()
            }
    }
    
    func onAction(perform action: @escaping () -> Void) -> some View {
        self.onAppear()
            .onDisappear()
            .background(KeyPressActionView(action: action))
    }
}

// Helper view to capture keyboard events
struct KeyPressActionView: View {
    let action: () -> Void
    
    var body: some View {
        EmptyView()
            .frame(width: 0, height: 0)
    }
}
