//
//  IgnoreDoubleClickModifier.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/5/25.
//

import SwiftUI
import AppKit

struct IgnoreDoubleClickModifier: ViewModifier {
    @State private var isClickInProgress = false
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isClickInProgress {
                            isClickInProgress = true
                            
                            // Block double-click notifications by creating a click outside the calendar area
                            if let window = NSApplication.shared.windows.first {
                                let outsidePoint = NSPoint(x: -100, y: -100) // Point outside window
                                let outsideEvent = NSEvent.mouseEvent(
                                    with: .leftMouseDown,
                                    location: outsidePoint,
                                    modifierFlags: [],
                                    timestamp: ProcessInfo().systemUptime,
                                    windowNumber: window.windowNumber,
                                    context: nil,
                                    eventNumber: 0,
                                    clickCount: 1,
                                    pressure: 1.0
                                )
                                if let event = outsideEvent {
                                    window.postEvent(event, atStart: false)
                                }
                            }
                        }
                    }
                    .onEnded { _ in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            isClickInProgress = false
                        }
                    }
            )
    }
}

extension View {
    func ignoreDoubleClick() -> some View {
        modifier(IgnoreDoubleClickModifier())
    }
}
