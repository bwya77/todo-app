//
//  ProjectCompletionIndicator.swift
//  todo-app
//
//  Created on 3/11/25.
//

import SwiftUI
import CoreData
import Combine
import Dispatch

/// A progress indicator for project completion that resembles a filling circle/pie chart
public struct ProjectCompletionIndicator: View {
    @ObservedObject var project: Project
    @Environment(\.managedObjectContext) private var viewContext
    
    private var isSelected: Bool
    private var size: CGFloat
    
    /// State object to track project completion
    @StateObject private var tracker: ProjectCompletionTracker
    
    /// For animation control
    @StateObject private var animator = CircleProgressAnimator()
    
    public init(project: Project, isSelected: Bool = false, size: CGFloat = 16, viewContext: NSManagedObjectContext) {
        self.project = project
        self.isSelected = isSelected
        self.size = size
        
        // Initialize the tracker with a unique instance for each project
        self._tracker = StateObject(wrappedValue: ProjectCompletionTracker(project: project))
    }
    
    public var body: some View {
        ZStack {
            // Empty circle (background/outline)
            Circle()
                .strokeBorder(
                    // Always use the project color for the outline
                    AppColors.getColor(from: project.color),
                    lineWidth: 1
                )
                .frame(width: size, height: size)
            
            if animator.currentProgress > 0 {
                // Inner circle that fills based on completion percentage
                Circle()
                    .stroke(AppColors.getColor(from: project.color), lineWidth: 1)
                    .frame(width: size * 0.6, height: size * 0.6)
                
                // Progress circle inside the inner circle
                Canvas { context, canvasSize in
                    // Define the center and radius of the inner circle
                    let center = CGPoint(x: canvasSize.width/2, y: canvasSize.height/2)
                    let radius = min(canvasSize.width, canvasSize.height) / 2
                    
                    // Create a path for the pie slice
                    var path = Path()
                    path.move(to: center)
                    path.addArc(center: center, radius: radius, startAngle: .degrees(-90), endAngle: .degrees(-90) + .degrees(360 * animator.currentProgress), clockwise: false)
                    path.closeSubpath()
                    
                    // Fill the path
                    context.fill(path, with: .color(AppColors.getColor(from: project.color)))
                }
                .frame(width: size * 0.56, height: size * 0.56) // Slightly smaller than the inner circle outline
            }
        }
        // Use a unique ID based on the project ID to force recreation when project changes
        .id("progress-\(project.id?.uuidString ?? UUID().uuidString)")
        .onAppear {
            // Force refresh when view appears
            tracker.refresh()
            animator.reset()
            animator.animateTo(tracker.completionPercentage)
        }
        .onChange(of: project) { oldProject, newProject in
            // Force refresh when the project changes
            if oldProject.id != newProject.id {
                tracker.updateProject(newProject.id)
                animator.reset()
                animator.animateTo(tracker.completionPercentage)
            } else {
                // The project is the same but might have been updated
                tracker.refresh()
                animator.animateTo(tracker.completionPercentage)
            }
        }
        .onDisappear {
            tracker.cleanup()
        }
        .onReceive(tracker.$completionPercentage) { newPercentage in
            animator.animateTo(newPercentage)
        }
    }
}
