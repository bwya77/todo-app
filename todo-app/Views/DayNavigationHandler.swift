import SwiftUI
import AppKit

// A specialized handler for day view navigation with higher threshold for sensitivity
struct DayNavigationHandler: NSViewRepresentable {
    var onPrevious: () -> Void
    var onNext: () -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = DayNavigationView()
        view.onPrevious = onPrevious
        view.onNext = onNext
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if let view = nsView as? DayNavigationView {
            view.onPrevious = onPrevious
            view.onNext = onNext
        }
    }
    
    // Custom NSView for handling day navigation with reduced sensitivity
    class DayNavigationView: NSView {
        var onPrevious: (() -> Void)?
        var onNext: (() -> Void)?
        private var isProcessing = false
        private var accumulatedDeltaX: CGFloat = 0
        private var lastEventTime = Date.distantPast
        
        // Higher threshold for day view
        private let horizontalThreshold: CGFloat = 80.0
        private let debounceTime: TimeInterval = 0.6
        
        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            self.wantsLayer = true
            self.layer?.backgroundColor = NSColor.clear.cgColor
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func scrollWheel(with event: NSEvent) {
            let now = Date()
            
            // Reset accumulated values if it's been a while
            if now.timeIntervalSince(lastEventTime) > 0.5 {
                accumulatedDeltaX = 0
            }
            
            lastEventTime = now
            
            // Skip if currently processing
            if isProcessing {
                super.scrollWheel(with: event)
                return
            }
            
            // Determine if this is a horizontal scroll or shift+scroll
            let isHorizontalGesture = abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY) * 1.5
            let isShiftScroll = event.modifierFlags.contains(.shift)
            
            if isHorizontalGesture || isShiftScroll {
                // Accumulate horizontal delta (or vertical delta if shift is pressed)
                let delta = isHorizontalGesture ? event.scrollingDeltaX : event.scrollingDeltaY
                accumulatedDeltaX += delta
                
                // Only trigger when threshold is met
                if abs(accumulatedDeltaX) >= horizontalThreshold {
                    isProcessing = true
                    
                    if accumulatedDeltaX > 0 {
                        onPrevious?()
                    } else {
                        onNext?()
                    }
                    
                    // Reset accumulated value
                    accumulatedDeltaX = 0
                    
                    // Prevent multiple triggers with longer delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + debounceTime) {
                        self.isProcessing = false
                    }
                    
                    return // Don't pass to super
                }
            } else {
                // Regular vertical scrolling - let it pass through
                accumulatedDeltaX = 0
            }
            
            super.scrollWheel(with: event)
        }
    }
}

// Extension for easier SwiftUI usage
extension View {
    func dayNavigationHandler(onPrevious: @escaping () -> Void, onNext: @escaping () -> Void) -> some View {
        self.background(DayNavigationHandler(onPrevious: onPrevious, onNext: onNext))
    }
}
