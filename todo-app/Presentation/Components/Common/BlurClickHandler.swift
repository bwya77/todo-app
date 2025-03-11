//
//  BlurClickHandler.swift
//  todo-app
//
//  Created on 3/10/25.
//

import SwiftUI
import AppKit

// This is a utility view that handles detecting when the user clicks away from a focused field
struct BlurClickHandler: NSViewRepresentable {
    var onBlur: () -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = ClickHandlerView()
        view.onMouseDown = onBlur
        
        // Make the view invisible but still catch events
        view.isHidden = false
        view.alphaValue = 0.01
        
        // Setup tracking area for the whole window
        DispatchQueue.main.async {
            if let window = view.window {
                let options: NSTrackingArea.Options = [.activeAlways, .inVisibleRect, .mouseEnteredAndExited, .mouseMoved]
                let trackingArea = NSTrackingArea(rect: window.contentView?.bounds ?? .zero, options: options, owner: view, userInfo: nil)
                window.contentView?.addTrackingArea(trackingArea)
            }
        }
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if let view = nsView as? ClickHandlerView {
            view.onMouseDown = onBlur
        }
    }
    
    // Custom view that can detect mouse down events anywhere
    class ClickHandlerView: NSView {
        var onMouseDown: (() -> Void)? = nil
        
        override func mouseDown(with event: NSEvent) {
            super.mouseDown(with: event)
            onMouseDown?()
        }
    }
}

// Extension to make it easier to use in SwiftUI
extension View {
    func withBlurClickHandler(_ action: @escaping () -> Void) -> some View {
        overlay(
            BlurClickHandler(onBlur: action)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        )
    }
}
