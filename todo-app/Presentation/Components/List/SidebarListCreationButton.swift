//
//  SidebarListCreationButton.swift
//  todo-app
//
//  Created on 3/20/25.
//

import SwiftUI
import CoreData

/// A coordinator for showing the list creation popup when clicking the "New List" button
struct SidebarListCreationController {
    @Binding var showingListCreationPopup: Bool
    @Binding var animatePopup: Bool
    
    var taskViewModel: TaskViewModel
    var viewContext: NSManagedObjectContext
    
    // Show the list creation popup
    func showListCreationPopup() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            showingListCreationPopup = true
            // Immediate animation looks better with scale effect
            animatePopup = true
        }
    }
    
    // Close popup with animation
    func closePopup() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            animatePopup = false
            
            // Give it time to animate out before removing from view hierarchy
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showingListCreationPopup = false
            }
        }
    }
}
