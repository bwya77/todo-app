//
//  HorizontalWheelScrollableView.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/6/25.
//

import SwiftUI
import AppKit

// A simple horizontal wheel scrolling view for week navigation
struct HorizontalWheelScrollableView: NSViewRepresentable {
    @Binding var visibleDate: Date
    let childContent: AnyView
    
    private let calendar = Calendar.current
    
    // MARK: - NSViewRepresentable conformance
    
    class Coordinator {
        var parent: HorizontalWheelScrollableView
        
        init(_ parent: HorizontalWheelScrollableView) {
            self.parent = parent
        }
        
        func navigateToPrevious() {
            // Same behavior as the previous button
            parent.visibleDate = parent.calendar.date(byAdding: .weekOfYear, value: -1, to: parent.visibleDate) ?? parent.visibleDate
        }
        
        func navigateToNext() {
            // Same behavior as the next button
            parent.visibleDate = parent.calendar.date(byAdding: .weekOfYear, value: 1, to: parent.visibleDate) ?? parent.visibleDate
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> NSView {
        let customView = CustomHorizontalWheelScrollView(frame: .zero)
        customView.previousHandler = {
            context.coordinator.navigateToPrevious()
        }
        customView.nextHandler = {
            context.coordinator.navigateToNext()
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
        if let customView = nsView as? CustomHorizontalWheelScrollView,
           let hostingView = customView.subviews.first as? NSHostingView<AnyView> {
            hostingView.rootView = childContent
        }
    }
    
    // MARK: - Custom NSView for handling horizontal scrolling
    
    final class CustomHorizontalWheelScrollView: NSView {
        var previousHandler: (() -> Void)? = nil
        var nextHandler: (() -> Void)? = nil
        var isProcessingScroll = false
        
        override func scrollWheel(with event: NSEvent) {
            // Avoid multiple rapid scroll events
            if isProcessingScroll {
                return
            }
            
            // For trackpad gestures and traditional horizontal mouse wheels
            if abs(event.deltaX) > 0.5 {
                isProcessingScroll = true
                
                if event.deltaX > 0 {
                    // Scrolling right (positive deltaX) -> previous (older week)
                    previousHandler?()
                } else {
                    // Scrolling left (negative deltaX) -> next (newer week)
                    nextHandler?()
                }
                
                // Debounce to prevent rapid scrolling
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.isProcessingScroll = false
                }
                return
            }
            
            // For mouse wheel with shift key or vertical scroll interpreted as horizontal
            if abs(event.deltaY) > 0.5 {
                isProcessingScroll = true
                
                if event.deltaY > 0 {
                    // Scrolling up (positive deltaY) -> next (newer week)
                    nextHandler?()
                } else {
                    // Scrolling down (negative deltaY) -> previous (older week)
                    previousHandler?()
                }
                
                // Debounce to prevent rapid scrolling
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.isProcessingScroll = false
                }
            }
        }
    }
}
