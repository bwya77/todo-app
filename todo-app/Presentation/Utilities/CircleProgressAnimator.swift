
//
//  CircleProgressAnimator.swift
//  todo-app
//
//  Created on 3/11/25.
//

import SwiftUI

/// A utility class that handles animated progress for circle indicators
class CircleProgressAnimator: ObservableObject {
    
    /// The target progress value (0.0 to 1.0)
    @Published var targetProgress: Double = 0.0
    
    /// The current animated progress value (0.0 to 1.0)
    @Published var currentProgress: Double = 0.0
    
    /// The animation duration in seconds
    private var animationDuration: Double = 0.4
    
    /// The number of steps to use in the animation
    private var animationSteps: Int = 100
    
    /// Work item for cancellable animations
    private var animationWorkItem: DispatchWorkItem?
    
    /// Animates to a new progress value
    /// - Parameter progress: Target progress value between 0.0 and 1.0
    func animateTo(_ progress: Double) {
        // Cancel any existing animation
        animationWorkItem?.cancel()
        
        // Set the target progress
        let oldTarget = targetProgress
        targetProgress = max(0, min(1, progress))
        
        // If the current progress is 0 and target is 0, and old target was also 0, no need to animate
        if currentProgress == 0 && targetProgress == 0 && oldTarget == 0 {
            return
        }
        
        // Calculate the animation parameters
        let stepSize = (targetProgress - currentProgress) / Double(animationSteps)
        let stepDuration = animationDuration / Double(animationSteps)
        
        // Create a new animation work item that will be captured by closures but referenced safely
        var newWorkItem: DispatchWorkItem?
        
        newWorkItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            // Perform the animation in steps
            for step in 1...self.animationSteps {
                // Schedule the step
                DispatchQueue.main.asyncAfter(deadline: .now() + (stepDuration * Double(step))) { [weak self, weak newWorkItem] in
                    // Skip if cancelled or self is deallocated
                    guard let self = self, let workItem = newWorkItem, !workItem.isCancelled else { return }
                    
                    // Update the current progress
                    self.currentProgress = self.currentProgress + stepSize
                    
                    // Ensure we end with the exact target value on the last step
                    if step == self.animationSteps {
                        self.currentProgress = self.targetProgress
                    }
                }
            }
        }
        
        // Store and execute the work item
        animationWorkItem = newWorkItem
        
        // Execute the animation if we have a valid work item
        if let workItem = newWorkItem {
            DispatchQueue.global(qos: .userInteractive).async(execute: workItem)
        }
    }
    
    /// Immediately sets the progress without animation
    /// - Parameter progress: Progress value between 0.0 and 1.0
    func setProgress(_ progress: Double) {
        // Cancel any existing animation
        animationWorkItem?.cancel()
        
        // Set both target and current progress
        targetProgress = max(0, min(1, progress))
        currentProgress = targetProgress
    }
    
    /// Reset the animator
    func reset() {
        // Cancel any existing animation
        animationWorkItem?.cancel()
        
        // Reset progress values
        targetProgress = 0.0
        currentProgress = 0.0
    }
}
