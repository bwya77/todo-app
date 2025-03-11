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
        
        // Initialize the tracker
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
            
            // Progress pie
            Canvas { context, size in
                // Define the center and radius of the circle
                let center = CGPoint(x: size.width/2, y: size.height/2)
                let radius = min(size.width, size.height) / 2
                
                // Create a path for the pie slice
                var path = Path()
                path.move(to: center)
                path.addArc(center: center, radius: radius, startAngle: .degrees(-90), endAngle: .degrees(-90) + .degrees(360 * animator.currentProgress), clockwise: false)
                path.closeSubpath()
                
                // Fill the path
                context.fill(path, with: .color(AppColors.getColor(from: project.color)))
            }
            .frame(width: size - 2, height: size - 2)
        }
        .id("progress-\(project.id?.uuidString ?? "")-\(tracker.completionPercentage)")
        .onAppear {
            // Force refresh when view appears
            tracker.refresh()
            animator.reset()
            animator.animateTo(tracker.completionPercentage)
        }
        .onDisappear {
            tracker.cleanup()
        }
        .onReceive(tracker.$completionPercentage) { newPercentage in
            animator.animateTo(newPercentage)
        }
    }
}
