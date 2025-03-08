//
//  WheelScrollableView.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/5/25.
//  Refactored according to improvement plan on 3/7/25.
//

import SwiftUI
import AppKit

// A simpler, more direct approach for mousewheel scrolling in month view
struct WheelScrollableView: NSViewRepresentable {
    @Binding var visibleMonth: Date
    let childContent: AnyView
    
    private let calendar = Calendar.current
    
    // Initialize the view with required properties - not needed for struct with property wrappers
    // Struct automatically gets memberwise initializers
    
    // MARK: - NSViewRepresentable conformance
    
    // Coordinator to handle state and callbacks between SwiftUI and AppKit
    class Coordinator {
        var parent: WheelScrollableView
        
        init(_ parent: WheelScrollableView) {
            self.parent = parent
        }
        
        func handleMonthChange(direction: CGFloat) {
            // direction is now explicitly normalized to +1.0 (up) or -1.0 (down)
            if direction > 0 {  // Scrolling up
                parent.visibleMonth = parent.calendar.date(byAdding: .month, value: -1, to: parent.visibleMonth) ?? parent.visibleMonth
            } else {  // Scrolling down
                parent.visibleMonth = parent.calendar.date(byAdding: .month, value: 1, to: parent.visibleMonth) ?? parent.visibleMonth
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> NSView {
        let customView = CustomWheelScrollView(frame: .zero)
        customView.monthChangeHandler = { direction in
            context.coordinator.handleMonthChange(direction: direction)
        }
        
        let hostingView = NSHostingView(rootView: childContent)
        customView.addSubview(hostingView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: customView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: customView.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: customView.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: customView.bottomAnchor)
        ])
        
        return customView
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        // Update the hosting view with the latest childContent
        if let customView = nsView as? CustomWheelScrollView,
           let hostingView = customView.subviews.first as? NSHostingView<AnyView> {
            hostingView.rootView = childContent
        }
    }
    
    // MARK: - Custom NSView for handling mouse wheel events
    
    final class CustomWheelScrollView: NSView {
        var monthChangeHandler: ((CGFloat) -> Void)? = nil
        var isProcessingScroll = false
        var lastScrollTime: Date = Date.distantPast
        var accumulatedDelta: CGFloat = 0
        let scrollThreshold: CGFloat = 12.0 // Increased threshold for more deliberate scrolling
        let debounceTime: TimeInterval = 1.0 // Longer delay to prevent accidental double scrolling
        
        override func scrollWheel(with event: NSEvent) {
            let currentTime = Date()
            
            // Reset accumulated delta if it's been a while since the last scroll
            if currentTime.timeIntervalSince(lastScrollTime) > 0.3 {
                accumulatedDelta = 0
            }
            
            // Accumulate scroll delta
            accumulatedDelta += event.deltaY
            lastScrollTime = currentTime
            
            // Check if we should process a month change
            if !isProcessingScroll && abs(accumulatedDelta) >= scrollThreshold {
                isProcessingScroll = true
                
                // Only pass the sign of the delta, ignoring magnitude
                let direction: CGFloat = accumulatedDelta > 0 ? 1.0 : -1.0
                monthChangeHandler?(direction)
                
                // Reset accumulated delta
                accumulatedDelta = 0
                
                // Prevent multiple triggers with a longer delay
                DispatchQueue.main.asyncAfter(deadline: .now() + debounceTime) {
                    self.isProcessingScroll = false
                }
            }
        }
    }
}

// Extension to help provide SwiftUI preview support
extension WheelScrollableView {
    static func preview(visibleMonth: Binding<Date>, content: AnyView) -> some View {
        WheelScrollableView(visibleMonth: visibleMonth, childContent: content)
    }
}
