//
//  SimpleSwipeDetector.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/6/25.
//

import SwiftUI
import AppKit

// SwiftUI modifier to detect trackpad horizontal swipes
struct SwipeGestureModifier: ViewModifier {
    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void
    
    func body(content: Content) -> some View {
        content
            .background(
                SwipeDetectorRepresentable(
                    onSwipeLeft: onSwipeLeft,
                    onSwipeRight: onSwipeRight
                )
            )
    }
}

// Extension for SwiftUI views
extension View {
    func onDetectorSwipeGesture(left: @escaping () -> Void, right: @escaping () -> Void) -> some View {
        self.modifier(SwipeGestureModifier(onSwipeLeft: left, onSwipeRight: right))
    }
}

// NSViewRepresentable for SwiftUI integration
struct SwipeDetectorRepresentable: NSViewRepresentable {
    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = SwipeDetectorView()
        view.onSwipeLeft = onSwipeLeft
        view.onSwipeRight = onSwipeRight
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if let view = nsView as? SwipeDetectorView {
            view.onSwipeLeft = onSwipeLeft
            view.onSwipeRight = onSwipeRight
        }
    }
}

// Custom NSView that detects swipe gestures using a custom approach
class SwipeDetectorView: NSView {
    var onSwipeLeft: (() -> Void)?
    var onSwipeRight: (() -> Void)?
    private var startPoint: NSPoint = .zero
    private var isTracking = false
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        // Make the view transparent
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.clear.cgColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func scrollWheel(with event: NSEvent) {
        // Only detect significant horizontal scroll events
        if abs(event.scrollingDeltaX) > 10 && abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY * 1.5) {
            // Only trigger once per gesture
            if !isTracking {
                isTracking = true
                
                if event.scrollingDeltaX > 0 {
                    print("Horizontal scroll right detected")
                    onSwipeRight?()
                } else {
                    print("Horizontal scroll left detected")
                    onSwipeLeft?()
                }
                
                // Reset after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.isTracking = false
                }
            }
        } else {
            // Let other events pass through
            super.scrollWheel(with: event)
        }
    }
}
