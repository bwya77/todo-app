//
//  AppDelegate.swift
//  todo-app
//
//  Created on 3/19/25.
//

import Cocoa
import SwiftUI
import CoreData

class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Simplified approach to ensure basic task order initialization
        let context = PersistenceController.shared.container.viewContext
        
        // Save any pending changes to ensure data consistency
        if context.hasChanges {
            try? context.save()
        }
    }
    
    /// Save task order changes to persistent storage
    private func saveTaskOrder() {
        print("💾 Saving task order changes to persistent storage")
        PersistentOrder.saveAllContexts()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        print("🛑 App terminating - saving final task order")
        // Force save any pending changes to ensure ordering is preserved
        PersistentOrder.saveAllContexts()
    }
    
    // Additional handlers to ensure data is saved

    func applicationDidResignActive(_ notification: Notification) {
        // App is going to background
        PersistentOrder.saveAllContexts()
    }
    
    func applicationWillHide(_ notification: Notification) {
        // App is being hidden
        PersistentOrder.saveAllContexts()
    }
}
