    // MARK: - Default Data
    
    /// Ensures we have default projects and tags in the database
    private func ensureDefaultData() {
        let context = PersistenceController.shared.container.viewContext
        
        // Check if we have any projects
        let projectRequest: NSFetchRequest<Project> = Project.fetchRequest()
        projectRequest.fetchLimit = 1
        
        do {
            let projectCount = try context.count(for: projectRequest)
            
            if projectCount == 0 {
                // Create default projects
                createDefaultProjects(in: context)
            }
        } catch {
            print("Error checking for projects: \(error)")
        }
        
        // Check if we have any tags
        let tagRequest: NSFetchRequest<Tag> = Tag.fetchRequest()
        tagRequest.fetchLimit = 1
        
        do {
            let tagCount = try context.count(for: tagRequest)
            
            if tagCount == 0 {
                // Create default tags
                createDefaultTags(in: context)
            }
        } catch {
            print("Error checking for tags: \(error)")
        }
    }
    
    /// Creates default projects if none exist
    private func createDefaultProjects(in context: NSManagedObjectContext) {
        let projectData = [
            ("Work", "blue"),
            ("Personal", "green"),
            ("Health", "red"),
            ("Finance", "orange")
        ]
        
        for (name, color) in projectData {
            let project = Project(context: context)
            project.id = UUID()
            project.name = name
            project.color = color
        }
        
        // Save the context
        do {
            try context.save()
            print("Created default projects")
        } catch {
            print("Error saving default projects: \(error)")
        }
    }
    
    /// Creates default tags if none exist
    private func createDefaultTags(in context: NSManagedObjectContext) {
        let tagData = [
            ("Important", "red"),
            ("Later", "orange"),
            ("Quick", "green"),
            ("Home", "blue"),
            ("Research", "purple")
        ]
        
        for (name, color) in tagData {
            let tag = Tag(context: context)
            tag.id = UUID()
            tag.name = name
            tag.color = color
        }
        
        // Save the context
        do {
            try context.save()
            print("Created default tags")
        } catch {
            print("Error saving default tags: \(error)")
        }
    }//
//  AppDelegate.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/5/25.
//  Refactored according to improvement plan on 3/7/25.
//  Updated on 3/9/25 to ensure default projects.
//

import AppKit
import SwiftUI
import CoreData

class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        
        // Set the calendar grid color to the exact RGB(245,245,245)
        configureCalendarGridColor()
        
        // Configure window appearance
        configureWindowAppearance()
        
        // Ensure we have default data
        ensureDefaultData()
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
