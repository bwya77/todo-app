//
//  AppDelegate.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/5/25.
//  Refactored according to improvement plan on 3/7/25.
//

import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        
        // Set the calendar grid color to the exact RGB(245,245,245)
        configureCalendarGridColor()
        
        // Configure window appearance
        configureWindowAppearance()
    }
    
    private func configureWindowAppearance() {
        if let window = NSApplication.shared.windows.first {
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.styleMask.insert(.fullSizeContentView)
            
            // Set the background color of the window
            window.backgroundColor = NSColor(red: 248/255, green: 250/255, blue: 251/255, alpha: 1.0)
            
            // Enable the toolbar to always be visible
            window.toolbarStyle = .unifiedCompact
        }
        
        // Register for window notifications to ensure proper toolbar operation
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidBecomeKey),
            name: NSWindow.didBecomeKeyNotification,
            object: nil
        )
        
        // Configure all windows at startup
        configureAllWindows()
    }
    
    @objc private func windowDidBecomeKey(notification: Notification) {
        if let window = notification.object as? NSWindow {
            // Make sure toolbar stays visible when window becomes key
            window.toolbar?.isVisible = true
        }
    }
    
    private func configureAllWindows() {
        // Apply settings to all application windows
        for window in NSApplication.shared.windows {
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.styleMask.insert(.fullSizeContentView)
            window.backgroundColor = NSColor(red: 248/255, green: 250/255, blue: 251/255, alpha: 1.0)
            window.toolbarStyle = .unifiedCompact
        }
        
        // Register for notification when new windows are added to the application
        NotificationCenter.default.addObserver(
            forName: NSApplication.didFinishRestoringWindowsNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.configureAllWindows()
        }
    }
}
