//
//  DaySwipeGesture.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/8/25.
//

import SwiftUI
import AppKit

// Global state specific to day navigation to ensure proper pacing
private var lastDayNavigationTime = Date.distantPast
private let dayNavigationCooldown: TimeInterval = 1.5  // Increased cooldown for day view
private var activeGestureCount = 0

// A specific gesture handler for day view with higher thresholds
extension View {
    // Day-specific gesture handler
    func onDaySwipeGesture(left: @escaping () -> Void, right: @escaping () -> Void) -> some View {
        self
            // SwiftUI drag gesture with higher thresholds for day view
            .gesture(
                DragGesture(minimumDistance: 60)  // Higher threshold than regular swipe
                    .onEnded { value in
                        // Even stricter horizontal requirement
                        if abs(value.translation.width) > abs(value.translation.height) * 2.0 && 
                           abs(value.translation.width) > 80 {  // Require more horizontal movement
                            
                            // Check for active gestures and respect cooldown
                            let now = Date()
                            if activeGestureCount > 0 || now.timeIntervalSince(lastDayNavigationTime) < dayNavigationCooldown {
                                return // Skip if another gesture is active or cooldown hasn't elapsed
                            }
                            
                            // Set our semaphore
                            activeGestureCount += 1
                            lastDayNavigationTime = now
                            
                            // Trigger the appropriate navigation
                            if value.translation.width < 0 {
                                left()
                            } else {
                                right()
                            }
                            
                            // Release the semaphore after a longer delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                activeGestureCount = max(0, activeGestureCount - 1)
                            }
                        }
                    }
            )
            // Add a specialized day view background handler
            .background(
                DaySwipeEventMonitorView(onLeft: left, onRight: right)
            )
    }
}

// Specialized version for day view with higher thresholds
struct DaySwipeEventMonitorView: NSViewRepresentable {
    let onLeft: () -> Void
    let onRight: () -> Void
    
    class Coordinator: NSObject {
        var parent: DaySwipeEventMonitorView
        var isProcessingScroll = false
        var lastEventTime = Date.distantPast
        var accumulatedDelta: CGFloat = 0
        
        init(_ parent: DaySwipeEventMonitorView) {
            self.parent = parent
        }
        
        @objc func handleWheelEvent(_ event: NSEvent) {
            let now = Date()
            
            // Skip if already processing a gesture
            if isProcessingScroll {
                return
            }
            
            // Reset accumulated delta if it's been a while
            if now.timeIntervalSince(lastEventTime) > 0.3 {
                accumulatedDelta = 0
            }
            
            lastEventTime = now
            
            // Much stricter horizontal dominance requirement
            if abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY * 2.0) {
                // Add to accumulated delta
                accumulatedDelta += event.scrollingDeltaX
                
                // Much higher threshold for day navigation
                if abs(accumulatedDelta) > 60 {  // Increased threshold for days
                    // Check global cooldown and semaphore
                    if activeGestureCount > 0 || now.timeIntervalSince(lastDayNavigationTime) < dayNavigationCooldown {
                        // Skip and reset accumulated delta
                        accumulatedDelta = 0
                        return
                    }
                    
                    // Set processing flag and increment semaphore
                    isProcessingScroll = true
                    activeGestureCount += 1
                    lastDayNavigationTime = now
                    
                    // Trigger appropriate callback
                    if accumulatedDelta > 0 {
                        parent.onRight()
                    } else {
                        parent.onLeft()
                    }
                    
                    // Reset accumulated delta
                    accumulatedDelta = 0
                    
                    // Release the processing flag and semaphore after a long delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {  // Increased to 1.5 seconds
                        self.isProcessingScroll = false
                        activeGestureCount = max(0, activeGestureCount - 1)
                    }
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        
        // Set up local monitor for scroll wheel events
        NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
            if event.window?.contentView?.hitTest(event.locationInWindow) != nil {
                context.coordinator.handleWheelEvent(event)
            }
            return event
        }
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        // Nothing to update
    }
}
