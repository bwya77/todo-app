//
//  SaveOrderObserver.swift
//  todo-app
//
//  Created on 3/19/25.
//

import Foundation
import SwiftUI
import CoreData

/// A view modifier that observes changes requiring task order saving
struct SaveOrderObserver: ViewModifier {
    // The managed object context to save when needed
    @Environment(\.managedObjectContext) private var viewContext
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                // Set up notification observer
                NotificationCenter.default.addObserver(
                    forName: NSNotification.Name("ForceContextSave"),
                    object: nil,
                    queue: .main
                ) { _ in
                    saveContext()
                }
            }
            .onDisappear {
                // Clean up by saving one last time
                saveContext()
            }
    }
    
    /// Save the managed object context
    private func saveContext() {
        do {
            if viewContext.hasChanges {
                try viewContext.save()
                print("📝 Context saved by SaveOrderObserver")
            }
        } catch {
            print("❌ Error saving context from observer: \(error)")
        }
    }
}

// Extension to make the modifier easier to use
extension View {
    func withSaveOrderObserver() -> some View {
        self.modifier(SaveOrderObserver())
    }
}
