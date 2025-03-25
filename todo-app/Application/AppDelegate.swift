//
//  AppDelegate.swift
//  todo-app
//
//  Created on 3/19/25.
//

import Cocoa
import SwiftUI
import CoreData
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    // Project navigation publisher
    let projectNavigationPublisher = PassthroughSubject<Project, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize DisplayOrderManager to ensure proper ordering for tasks and projects
        print("🚀 Initializing DisplayOrderManager for tasks and projects")
        DisplayOrderManager.ensureDisplayOrderExists()
        DisplayOrderManager.repairAllTaskOrder()
        DisplayOrderManager.repairAllProjectOrder()
        
        // Initialize task order at launch
        AppLaunchTaskOrderInitializer.shared.initializeTaskOrder()
        
        // Save any pending changes to ensure data consistency
        let context = PersistenceController.shared.container.viewContext
        if context.hasChanges {
            try? context.save()
        }
        
        // Setup project navigation notification observer
        setupProjectNavigationObserver()
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
    
    // MARK: - Project Navigation
    
    /// Setup the observer for project navigation notifications
    private func setupProjectNavigationObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleProjectNavigation),
            name: NSNotification.Name("NavigateToProject"),
            object: nil
        )
    }
    
    /// Handle project navigation from notification
    @objc private func handleProjectNavigation(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let project = userInfo["project"] as? Project else {
            return
        }
        
        // Publish the project to navigate to
        projectNavigationPublisher.send(project)
    }
}
