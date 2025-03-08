//
//  DoubleClickModifier.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/5/25.
//

import SwiftUI

// Simple modifier - we're handling double-clicks in the AppDelegate instead
struct DoubleClickModifier: ViewModifier {
    let date: Date
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onTapGesture(perform: action)
    }
}

extension View {
    func onDoubleClick(date: Date, action: @escaping () -> Void = {}) -> some View {
        self.modifier(DoubleClickModifier(date: date, action: action))
    }
}
