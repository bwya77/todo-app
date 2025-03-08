//
//  AppDelegate+GridColor.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/5/25.
//  Refactored according to improvement plan on 3/7/25.
//

import AppKit
import SwiftUI

extension AppDelegate {
    // Call this at app launch to set the standard grid color
    func configureCalendarGridColor() {
        // Set color values for calendar grids in user defaults
        UserDefaults.standard.set([245.0, 245.0, 245.0], forKey: "AppleSeparatorColor")
    }
}
