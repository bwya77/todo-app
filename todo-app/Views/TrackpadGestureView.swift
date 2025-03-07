//
//  TrackpadGestureView.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/6/25.
//

import SwiftUI
import AppKit

// Alternative approach using event tracking for trackpad gestures
class SwipeDetectingView: NSView {
    var onSwipeLeft: (() -> Void)? = nil
    var onSwipeRight: (() -> Void)? = nil
    private var initialX: CGFloat = 0
    private var isTracking = false
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.clear.cgColor
        
        // Accept scroll wheel events
        self.postsFrameChangedNotifications = true
        self.postsBoundsChangedNotifications = true
        self.enclosingScrollView?.hasHorizontalScroller = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func mouseDown(with event: NSEvent) {
        // Reset tracking state
        initialX = event.locationInWindow.x
        isTracking = true
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard isTracking else { return }
        
        let currentX = event.locationInWindow.x
        let deltaX = currentX - initialX
        
        // Only detect significant horizontal movements (threshold of 50 points)
        if abs(deltaX) > 50 {
            if deltaX > 0 {
                print("Detected right swipe")
                onSwipeRight?()
            } else {
                print("Detected left swipe")
                onSwipeLeft?()
            }
            isTracking = false // Stop tracking after detecting a gesture
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        isTracking = false
    }
    
    override func scrollWheel(with event: NSEvent) {
        // Check if this is primarily a horizontal scroll
        let isHorizontalScroll = abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY * 1.5)
        
        if isHorizontalScroll && abs(event.scrollingDeltaX) > 3 {
            // This appears to be an intentional horizontal scroll
            if !isTracking {
                isTracking = true
                
                // Use scrollingDeltaX for direction (positive is right, negative is left)
                if event.scrollingDeltaX > 0 {
                    print("Detected right scroll: \(event.scrollingDeltaX)")
                    onSwipeRight?()
                } else {
                    print("Detected left scroll: \(event.scrollingDeltaX)")
                    onSwipeLeft?()
                }
                
                // Reset tracking after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.isTracking = false
                }
                
                // Don't pass horizontal scrolls to next responder
                return
            }
        }
        
        // Always pass vertical scrolls through to next responder
        super.scrollWheel(with: event)
    }
}

struct TrackpadGestureView: NSViewRepresentable {
    var onSwipeLeft: () -> Void
    var onSwipeRight: () -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = SwipeDetectingView()
        view.onSwipeLeft = onSwipeLeft
        view.onSwipeRight = onSwipeRight
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if let view = nsView as? SwipeDetectingView {
            view.onSwipeLeft = onSwipeLeft
            view.onSwipeRight = onSwipeRight
        }
    }
}

struct TrackpadGestureModifier: ViewModifier {
    var onSwipeLeft: () -> Void
    var onSwipeRight: () -> Void
    
    func body(content: Content) -> some View {
        content.background(
            TrackpadGestureView(onSwipeLeft: onSwipeLeft, onSwipeRight: onSwipeRight)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        )
    }
}

extension View {
    func trackpadGestures(onSwipeLeft: @escaping () -> Void, onSwipeRight: @escaping () -> Void) -> some View {
        modifier(TrackpadGestureModifier(onSwipeLeft: onSwipeLeft, onSwipeRight: onSwipeRight))
    }
}
