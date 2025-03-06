//
//  NavigationButtonClicksHandler.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/5/25.
//

import SwiftUI

// For navigation buttons to prevent them from triggering day selection
struct SingleClickOnlyButtonStyle: ButtonStyle {
    let position: ButtonPosition
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                Group {
                    switch position {
                    case .left:
                        RoundedCorners(tl: 4, tr: 0, bl: 4, br: 0)
                            .fill(configuration.isPressed ? Color(NSColor.controlColor) : Color(NSColor.controlBackgroundColor))
                    case .center:
                        Rectangle()
                            .fill(configuration.isPressed ? Color(NSColor.controlColor) : Color(NSColor.controlBackgroundColor))
                    case .right:
                        RoundedCorners(tl: 0, tr: 4, bl: 0, br: 4)
                            .fill(configuration.isPressed ? Color(NSColor.controlColor) : Color(NSColor.controlBackgroundColor))
                    }
                }
            )
            .overlay(
                Group {
                    switch position {
                    case .left:
                        RoundedCorners(tl: 4, tr: 0, bl: 4, br: 0)
                            .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                    case .center:
                        Rectangle()
                            .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                    case .right:
                        RoundedCorners(tl: 0, tr: 4, bl: 0, br: 4)
                            .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                    }
                }
            )
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}
