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

@main
struct TodoApp: App {
    let persistenceController = PersistenceController.shared
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .frame(minWidth: 1000, minHeight: 700)
                .onAppear {
                    setupAppearance()
                    
                    // Ensure we have default data
                    DefaultDataProvider.shared.ensureDefaultData()
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
