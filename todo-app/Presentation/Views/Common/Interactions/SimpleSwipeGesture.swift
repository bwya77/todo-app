//
//  SimpleSwipeGesture.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/8/25.
//

import SwiftUI
import AppKit

// Global state to track last navigation action across all handlers
private var lastGlobalNavigationTime = Date.distantPast
private let globalNavigationCooldown: TimeInterval = 0.5  // Reduced from 0.7 to 0.5 seconds for better responsiveness

// A single gesture handler that combines SwiftUI, AppKit and NSEvent monitoring
extension View {
    // Main method to add swipe gesture support to a view
    func onSwipeGesture(left: @escaping () -> Void, right: @escaping () -> Void) -> some View {
        self
            // SwiftUI drag gesture for touch support
            .gesture(
                DragGesture(minimumDistance: 25)  // Reduced from 40 to 25 for better sensitivity
                    .onEnded { value in
                        // Make sure it's primarily horizontal and has sufficient movement
                        if abs(value.translation.width) > abs(value.translation.height) * 1.5 && 
                           abs(value.translation.width) > 30 {  // Reduced from 60 to 30 for better sensitivity
                            
                            // Check global cooldown to avoid rapid navigation
                            let now = Date()
                            if now.timeIntervalSince(lastGlobalNavigationTime) < globalNavigationCooldown {
                                return // Skip this gesture if too soon after last action
                            }
                            lastGlobalNavigationTime = now
                            
                            if value.translation.width < 0 {
                                left()
                            } else {
                                right()
                            }
                        }
                    }
            )
            // Add a background view to detect NSEvent events like trackpad swipes
            .background(
                SwipeEventMonitorView(onLeft: left, onRight: right)
            )
    }
}

// Implementation of AppKit event monitor for SwiftUI
struct SwipeEventMonitorView: NSViewRepresentable {
    let onLeft: () -> Void
    let onRight: () -> Void
    
    class Coordinator: NSObject {
        var parent: SwipeEventMonitorView
        var isProcessingScroll = false
        var lastEventTime = Date.distantPast
        var accumulatedDelta: CGFloat = 0
        
        init(_ parent: SwipeEventMonitorView) {
            self.parent = parent
        }
        
        @objc func handleWheelEvent(_ event: NSEvent) {
            let now = Date()
            
            // Skip if already processing a gesture
            if isProcessingScroll {
                return
            }
            
            // Reset accumulated delta if it's been a while since last event
            if now.timeIntervalSince(lastEventTime) > 0.3 {
                accumulatedDelta = 0
            }
            
            lastEventTime = now
            
            // Only process horizontal scrolls that are dominant
            if abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY * 1.5) {
                // Add to our accumulated delta
                accumulatedDelta += event.scrollingDeltaX
                
                // Higher threshold to prevent too many triggers
                // Only trigger when accumulated delta gets higher than threshold
                if abs(accumulatedDelta) > 30 {  // Increased from 10 to 30
                    // Check global cooldown
                    if now.timeIntervalSince(lastGlobalNavigationTime) < globalNavigationCooldown {
                        // Skip if too soon after last action
                        accumulatedDelta = 0
                        return
                    }
                    
                    isProcessingScroll = true
                    lastGlobalNavigationTime = now  // Update global timestamp
                    
                    // Trigger appropriate callback
                    if accumulatedDelta > 0 {
                        parent.onRight()
                    } else {
                        parent.onLeft()
                    }
                    
                    // Reset accumulated delta
                    accumulatedDelta = 0
                    
                    // Longer debounce time to prevent multiple triggers
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {  // Increased from 0.5 to 0.8
                        self.isProcessingScroll = false
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
