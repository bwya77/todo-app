//
//  ViewInspectorExtensions.swift
//  todo-appTests
//
//  Created on 3/25/25.
//

import SwiftUI
import ViewInspector

// This file provides extensions needed for ViewInspector to work with our custom components

extension Button: Inspectable {}
extension HStack: Inspectable {}
extension VStack: Inspectable {}
extension ZStack: Inspectable {}
extension Text: Inspectable {}
extension Image: Inspectable {}

// Make the test compile even if ViewInspector isn't fully available
#if DEBUG
// Enable mocking of SwiftUI views for testing
extension View {
    func accessibilityLabel(_ label: Text) -> some View {
        return self
    }
    
    func accessibilityLabel(_ label: String) -> some View {
        return self
    }
}
#endif
