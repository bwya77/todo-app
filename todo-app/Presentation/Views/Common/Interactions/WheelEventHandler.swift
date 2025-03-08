//
//  WheelEventHandler.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/5/25.
//  This file is deprecated in favor of SimpleSwipeGesture.swift
//

import SwiftUI
import AppKit

// Empty implementation to avoid compilation errors
// The functionality has been moved to SimpleSwipeGesture.swift
struct WheelEventHandler {
    // This empty implementation exists only to satisfy the compiler
    // Do not use this class - use SimpleSwipeGesture.swift instead
}

// Extension that provides a no-op implementation to avoid build errors
extension View {
    // This is a placeholder method to prevent build errors
    // The actual implementation is in SimpleSwipeGesture.swift
    @available(*, deprecated, message: "Use onSwipeGesture from SimpleSwipeGesture.swift instead")
    func onWheelEvent(handler: @escaping (CGFloat) -> Void) -> some View {
        // Return the view unchanged
        return self
    }
}
