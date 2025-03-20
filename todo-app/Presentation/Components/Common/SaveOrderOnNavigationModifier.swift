//
//  SaveOrderOnNavigationModifier.swift
//  todo-app
//
//  Created on 3/20/25.
//

import SwiftUI
import CoreData

/// A view modifier that ensures task order is saved when navigating between views
struct SaveOrderOnNavigationModifier: ViewModifier {
    @Environment(\.managedObjectContext) private var viewContext
    
    func body(content: Content) -> some View {
        content
            .onDisappear {
                // Save changes when the view disappears
                if viewContext.hasChanges {
                    try? viewContext.save()
                }
            }
    }
}

// Extension to make the modifier easier to use
extension View {
    func withSaveOrderOnNavigation() -> some View {
        self.modifier(SaveOrderOnNavigationModifier())
    }
}
