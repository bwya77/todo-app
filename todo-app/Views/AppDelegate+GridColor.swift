import AppKit
import SwiftUI

extension AppDelegate {
    // Call this at app launch to set the standard grid color
    func configureCalendarGridColor() {
        // Set color values for calendar grids in user defaults
        UserDefaults.standard.set([245.0, 245.0, 245.0], forKey: "AppleSeparatorColor")
    }
}
