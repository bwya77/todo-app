//
//  ProjectNavigationHelper.swift
//  todo-app
//
//  Created on 3/25/25.
//

import SwiftUI
import CoreData
import Combine

/// Helper for handling project navigation from different views
class ProjectNavigationHelper {
    static let shared = ProjectNavigationHelper()
    
    // Storage for cancellables
    var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Setup notification observer
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleProjectSelection),
            name: NSNotification.Name("SelectProject"),
            object: nil
        )
    }
    
    @objc func handleProjectSelection(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let project = userInfo["project"] as? Project else {
            return
        }
        
        // Post to the AppDelegate to handle the navigation
        NotificationCenter.default.post(
            name: NSNotification.Name("NavigateToProject"),
            object: nil,
            userInfo: ["project": project]
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

/// View modifier to enable project navigation via double click
struct ProjectNavigationModifier: ViewModifier {
    let project: Project
    
    func body(content: Content) -> some View {
        content
            .onTapGesture(count: 2) {
                NotificationCenter.default.post(
                    name: NSNotification.Name("SelectProject"),
                    object: nil,
                    userInfo: ["project": project]
                )
            }
    }
}

extension View {
    /// Adds project navigation via double click
    /// - Parameter project: The project to navigate to
    /// - Returns: Modified view
    func navigateToProjectOnDoubleClick(project: Project) -> some View {
        self.modifier(ProjectNavigationModifier(project: project))
    }
}
