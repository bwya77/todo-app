//
//  App.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/4/25.
//  Refactored according to improvement plan on 3/7/25.
//  Updated on 3/9/25 to include default data population.
//

import SwiftUI
import AppKit
import Combine

@main
struct TodoApp: App {
    let persistenceController = PersistenceController.shared
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .frame(minWidth: 1000, minHeight: 700)
                .ignoreAppInactiveState() // Force app to maintain its appearance when inactive
                .onAppear {
                    setupAppearance()
                    
                    // Ensure we have default data
                    DefaultDataProvider.shared.ensureDefaultData()
                    
                    // Initialize DisplayOrderManager for tasks and projects
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        print("🚀 Initializing DisplayOrderManager from SwiftUI App")
                        DisplayOrderManager.ensureDisplayOrderExists()
                        DisplayOrderManager.repairAllTaskOrder()
                        DisplayOrderManager.repairAllProjectOrder()
                    }
                    
                    // Initialize the project navigation helper
                    _ = ProjectNavigationHelper.shared
                }
        }
        .windowToolbarStyle(.unifiedCompact)
        .windowStyle(.hiddenTitleBar)
    }
    
    private func setupAppearance() {
        // Set the app name in the menu bar
        NSApp.mainMenu?.items.first?.title = "Todo App"
        
        // Set up global window appearance settings
        NSWindow.allowsAutomaticWindowTabbing = false
    }
}
