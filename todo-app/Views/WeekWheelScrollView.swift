//
//  WeekWheelScrollView.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/6/25.
//

import SwiftUI
import AppKit

// A simple wheel scroll view specifically for week navigation
struct WeekWheelScrollView: NSViewRepresentable {
    @Binding var visibleDate: Date
    let childContent: AnyView
    
    private let calendar = Calendar.current
    
    // MARK: - NSViewRepresentable conformance
    
    class Coordinator {
        var parent: WeekWheelScrollView
        
        init(_ parent: WeekWheelScrollView) {
            self.parent = parent
        }
        
        func handlePrevWeek() {
            parent.visibleDate = parent.calendar.date(byAdding: .weekOfYear, value: -1, to: parent.visibleDate) ?? parent.visibleDate
        }
        
        func handleNextWeek() {
            parent.visibleDate = parent.calendar.date(byAdding: .weekOfYear, value: 1, to: parent.visibleDate) ?? parent.visibleDate
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> NSView {
        let customView = WeekWheelScrollNSView(frame: .zero)
        customView.onPrevWeek = {
            context.coordinator.handlePrevWeek()
        }
        customView.onNextWeek = {
            context.coordinator.handleNextWeek()
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
        if let hostingView = nsView.subviews.first as? NSHostingView<AnyView> {
            hostingView.rootView = childContent
        }
    }
    
    // MARK: - Custom NSView for handling wheel events
    
    final class WeekWheelScrollNSView: NSView {
        var onPrevWeek: (() -> Void)? = nil
        var onNextWeek: (() -> Void)? = nil
        var isProcessing = false
        
        override func scrollWheel(with event: NSEvent) {
            // Avoid processing another event while one is in progress
            if isProcessing {
                return
            }
            
            isProcessing = true
            
            // Handle horizontal scroll (left/right swipe on trackpad)
            if abs(event.deltaX) > 0.5 {
                if event.deltaX > 0 {
                    // Right swipe -> previous week
                    onPrevWeek?()
                } else {
                    // Left swipe -> next week
                    onNextWeek?()
                }
            }
            // Handle vertical scroll (typical mouse wheel)
            else if abs(event.deltaY) > 0.5 {
                if event.deltaY > 0 {
                    // Scroll up -> previous week
                    onPrevWeek?()
                } else {
                    // Scroll down -> next week
                    onNextWeek?()
                }
            }
            
            // Reset after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.isProcessing = false
            }
        }
    }
}
