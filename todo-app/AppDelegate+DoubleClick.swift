//
//  AppDelegate+DoubleClick.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/5/25.
//

import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        
        // Set the calendar grid color to the exact RGB(245,245,245)
        configureCalendarGridColor()
    }
}
