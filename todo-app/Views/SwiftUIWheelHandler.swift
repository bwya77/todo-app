import SwiftUI
import AppKit

// A SwiftUI modifier to handle wheel events
struct WheelEventHandlerModifier: ViewModifier {
    var onLeft: () -> Void
    var onRight: () -> Void
    
    func body(content: Content) -> some View {
        content
            .background(WheelEventHandlerView(onLeft: onLeft, onRight: onRight))
    }
    
    // NSViewRepresentable to handle wheel events
    struct WheelEventHandlerView: NSViewRepresentable {
        var onLeft: () -> Void
        var onRight: () -> Void
        
        class Coordinator: NSObject {
            var parent: WheelEventHandlerView
            var lastEventTime: Date = .distantPast
            var isProcessing = false
            var accumulatedDeltaX: CGFloat = 0
            var accumulatedDeltaY: CGFloat = 0
            let horizontalThreshold: CGFloat = 30.0 // Higher threshold for horizontal scrolling
            let verticalThreshold: CGFloat = 40.0   // Even higher threshold for vertical scrolling
            let debounceTime: TimeInterval = 0.5   // Longer debounce time
            
            init(_ parent: WheelEventHandlerView) {
                self.parent = parent
            }
            
            @objc func handleScrollWheel(_ event: NSEvent) {
                let now = Date()
                
                // Reset accumulated values if it's been a while
                if now.timeIntervalSince(lastEventTime) > 0.5 {
                    accumulatedDeltaX = 0
                    accumulatedDeltaY = 0
                }
                
                lastEventTime = now
                
                // Skip if currently processing
                if isProcessing {
                    return
                }
                
                // Accumulate deltas
                if abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY) {
                    // Primarily horizontal scroll
                    accumulatedDeltaX += event.scrollingDeltaX
                    accumulatedDeltaY = 0  // Reset vertical when horizontal is dominant
                    
                    // Only trigger when threshold is met
                    if abs(accumulatedDeltaX) >= horizontalThreshold {
                        isProcessing = true
                        
                        if accumulatedDeltaX > 0 {
                            parent.onRight()
                        } else {
                            parent.onLeft()
                        }
                        
                        // Reset accumulated values
                        accumulatedDeltaX = 0
                        accumulatedDeltaY = 0
                        
                        // Prevent multiple triggers with longer delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + debounceTime) {
                            self.isProcessing = false
                        }
                    }
                } 
                // Handle vertical scrolling (give more resistance)
                else if abs(event.scrollingDeltaY) > 0.5 {
                    // Vertical scrolling only triggers horizontal navigation if shift key is pressed
                    // This ensures regular vertical scrolling works normally in day view
                    if event.modifierFlags.contains(.shift) {
                        accumulatedDeltaY += event.scrollingDeltaY
                        accumulatedDeltaX = 0  // Reset horizontal when vertical is dominant
                        
                        // Require higher threshold for vertical scrolling
                        if abs(accumulatedDeltaY) >= verticalThreshold {
                            isProcessing = true
                            
                            if accumulatedDeltaY > 0 {
                                parent.onRight()
                            } else {
                                parent.onLeft()
                            }
                            
                            // Reset accumulated values
                            accumulatedDeltaX = 0
                            accumulatedDeltaY = 0
                            
                            // Prevent multiple triggers with longer delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + debounceTime) {
                                self.isProcessing = false
                            }
                        }
                    } else {
                        // Regular vertical scrolling - let it pass through
                        accumulatedDeltaY = 0
                    }
                }
            }
        }
        
        func makeCoordinator() -> Coordinator {
            return Coordinator(self)
        }
        
        func makeNSView(context: Context) -> NSView {
            let view = WheelCaptureView()
            view.coordinator = context.coordinator
            
            // Register for scroll wheel events
            NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
                if event.window == view.window {
                    context.coordinator.handleScrollWheel(event)
                }
                return event
            }
            
            return view
        }
        
        func updateNSView(_ nsView: NSView, context: Context) {
            if let view = nsView as? WheelCaptureView {
                view.coordinator = context.coordinator
            }
        }
        
        class WheelCaptureView: NSView {
            var coordinator: Coordinator?
            
            override func scrollWheel(with event: NSEvent) {
                coordinator?.handleScrollWheel(event)
                super.scrollWheel(with: event)
            }
        }
    }
}

// Extension for easier SwiftUI usage
extension View {
    func onWheelEvent(left: @escaping () -> Void, right: @escaping () -> Void) -> some View {
        self.modifier(WheelEventHandlerModifier(onLeft: left, onRight: right))
    }
}
