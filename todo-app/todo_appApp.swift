//
//  todo_appApp.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/4/25.
//

import SwiftUI

@main
struct todo_appApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .frame(minWidth: 1000, minHeight: 700)
                .onAppear {
                    setupAppearance()
                }
        }
        .windowToolbarStyle(.automatic)
        .windowStyle(.hiddenTitleBar)
    }
    
    private func setupAppearance() {
        // Set the app name in the menu bar
        NSApp.mainMenu?.items.first?.title = "Todo App"
        
        // Hide title bar completely
        if let window = NSApplication.shared.windows.first {
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.styleMask.insert(.fullSizeContentView)
            
            // Set the background color of the window
            window.backgroundColor = NSColor(red: 248/255, green: 250/255, blue: 251/255, alpha: 1.0)
            
            // Make sure we're using the exact RGB(248, 250, 251) for the sidebar background
            // Use explicit color settings that won't be overridden
            
            // Make sure toolbar is hidden
            window.toolbar?.isVisible = false
            
            // Set up notification to keep toolbar hidden when scrolling
            NotificationCenter.default.addObserver(forName: NSScrollView.didLiveScrollNotification, object: nil, queue: .main) { _ in
                window.toolbar?.isVisible = false
            }
        }
    }
}
