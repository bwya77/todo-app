//
//  AppDelegate+DoubleClick.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/5/25.
//

import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var clickMonitor: Any?
    private var lastClickTime: Date = .distantPast
    private var clickCount: Int = 0
    private let doubleClickThreshold: TimeInterval = 0.5
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Use a global monitor for mouse clicks
        NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .leftMouseUp]) { [weak self] event in
            guard let self = self else { return event }
            
            let currentTime = Date()
            
            // If this is a mouse down event
            if event.type == .leftMouseDown {
                // Reset counter if it's been too long since last click
                if currentTime.timeIntervalSince(self.lastClickTime) > self.doubleClickThreshold {
                    self.clickCount = 0
                }
                
                // Increment click counter
                self.clickCount += 1
                
                // If this is a second click (double-click)
                if self.clickCount == 2 {
                    // Check if we're in a calendar view
                    if let window = event.window, 
                       window.title.lowercased().contains("todo") || window.title.isEmpty {
                        self.handleDoubleClick()
                    }
                    
                    // Reset click counter
                    self.clickCount = 0
                }
                
                // Update last click time
                self.lastClickTime = currentTime
            }
            
            return event
        }
    }
    
    private func handleDoubleClick() {
        // Post notification to switch to day view for the currently selected date
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: CalendarKitView.switchToDayViewNotification,
                object: Date() // The view will use the selected date
            )
        }
    }
}
