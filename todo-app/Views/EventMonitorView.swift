import SwiftUI
import AppKit

// A SwiftUI view to capture all relevant gestures and wheel events
struct EventMonitorView: NSViewRepresentable {
    var onSwipeLeft: () -> Void
    var onSwipeRight: () -> Void
    
    class Coordinator: NSObject {
        var parent: EventMonitorView
        var isProcessing = false
        
        init(_ parent: EventMonitorView) {
            self.parent = parent
        }
        
        // Handle left swipe (newer week)
        @objc func handleSwipeLeft(_ gesture: NSPanGestureRecognizer) {
            if gesture.state == .ended && !isProcessing {
                let translation = gesture.translation(in: gesture.view)
                let velocity = gesture.velocity(in: gesture.view)
                
                // Check if this was actually a leftward swipe with sufficient movement and velocity
                if translation.x < -50 && abs(translation.x) > abs(translation.y) && velocity.x < -300 {
                    isProcessing = true
                    parent.onSwipeLeft()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.isProcessing = false
                    }
                }
            }
        }
        
        // Handle right swipe (older week)
        @objc func handleSwipeRight(_ gesture: NSPanGestureRecognizer) {
            if gesture.state == .ended && !isProcessing {
                let translation = gesture.translation(in: gesture.view)
                let velocity = gesture.velocity(in: gesture.view)
                
                // Check if this was actually a rightward swipe with sufficient movement and velocity
                if translation.x > 50 && abs(translation.x) > abs(translation.y) && velocity.x > 300 {
                    isProcessing = true
                    parent.onSwipeRight()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.isProcessing = false
                    }
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> NSView {
        let view = GestureRecognizingView()
        
        // Add swipe gesture recognizers
        let swipeLeft = NSPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleSwipeLeft(_:)))
        view.addGestureRecognizer(swipeLeft)
        
        let swipeRight = NSPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleSwipeRight(_:)))
        view.addGestureRecognizer(swipeRight)
        
        // We're not handling wheel events here, we'll rely on SwiftUIWheelHandler for that
        view.onWheelEvent = { _ in }
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        // No need to update
    }
    
    // Custom NSView that handles scroll wheel events
    class GestureRecognizingView: NSView {
        var onWheelEvent: ((NSEvent) -> Void)?
        
        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            self.wantsLayer = true
            self.layer?.backgroundColor = NSColor.clear.cgColor
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func scrollWheel(with event: NSEvent) {
            onWheelEvent?(event)
            super.scrollWheel(with: event)
        }
        
        // Ensure the view can accept first responder
        override var acceptsFirstResponder: Bool {
            return true
        }
    }
}

// Extension to add event monitoring to any SwiftUI view
extension View {
    func monitorEvents(onSwipeLeft: @escaping () -> Void, onSwipeRight: @escaping () -> Void) -> some View {
        background(EventMonitorView(onSwipeLeft: onSwipeLeft, onSwipeRight: onSwipeRight))
    }
}
