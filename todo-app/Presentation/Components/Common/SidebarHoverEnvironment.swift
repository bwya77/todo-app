//
//  SidebarHoverEnvironment.swift
//  todo-app
//
//  Created on 3/25/25.
//

import SwiftUI
import Combine

/// Environment key to track whether the mouse is hovering over the sidebar
private struct SidebarHoverEnvironmentKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

/// Environment value extension to access sidebar hover state
extension EnvironmentValues {
    var isSidebarHovered: Bool {
        get { self[SidebarHoverEnvironmentKey.self] }
        set { self[SidebarHoverEnvironmentKey.self] = newValue }
    }
}

/// Observable object to track sidebar hover state application-wide
public class SidebarHoverState: ObservableObject {
    @Published public var isHovered: Bool = false
    
    // Create a singleton instance for app-wide access
    public static let shared = SidebarHoverState()
    
    private init() {}
}

/// View modifier to detect hover over the sidebar
public struct SidebarHoverModifier: ViewModifier {
    // Access the shared hover state
    @ObservedObject var hoverState = SidebarHoverState.shared
    
    public func body(content: Content) -> some View {
        content
            .onHover { isHovered in
                if hoverState.isHovered != isHovered {
                    hoverState.isHovered = isHovered
                }
            }
            // Pass the hover state to all child views through environment
            .transformEnvironment(\.isSidebarHovered) { value in
                value = hoverState.isHovered
            }
    }
}

/// View extension to add sidebar hover detection
extension View {
    /// Adds sidebar hover detection that will make the hover state available
    /// to all child views through environment
    public func detectSidebarHover() -> some View {
        self.modifier(SidebarHoverModifier())
    }
}
