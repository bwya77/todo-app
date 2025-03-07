//
//  CalendarNavigation.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/5/25.
//

import SwiftUI

struct CalendarNavigation: View {
    // Callback functions for navigation actions
    var onPrevious: () -> Void
    var onToday: () -> Void
    var onNext: () -> Void
    
    var body: some View {
        HStack(spacing: 1) {
            // Left arrow button in its own container
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 30, height: 24)
            }
            .buttonStyle(SingleClickOnlyButtonStyle(position: .left))
            .accessibilityLabel("calendar-navigation-button")
            
            // Today button in the middle
            Button(action: onToday) {
                Text("Today")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.primary)
                    .frame(height: 24)
                    .padding(.horizontal, 8)
            }
            .buttonStyle(SingleClickOnlyButtonStyle(position: .center))
            .accessibilityLabel("calendar-navigation-button")
            
            // Right arrow button in its own container
            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 30, height: 24)
            }
            .buttonStyle(SingleClickOnlyButtonStyle(position: .right))
            .accessibilityLabel("calendar-navigation-button")
        }
    }
}

// Position enum for button styling
enum ButtonPosition {
    case left, center, right
}

// Custom button style mimicking macOS Calendar navigation
struct MacOSNavigationButtonStyle: ButtonStyle {
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

// Custom shape for rounded corners on specific sides
struct RoundedCorners: Shape {
    var tl: CGFloat = 0.0
    var tr: CGFloat = 0.0
    var bl: CGFloat = 0.0
    var br: CGFloat = 0.0
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.size.width
        let height = rect.size.height
        
        // Top left corner
        path.move(to: CGPoint(x: 0, y: tl))
        if tl != 0 {
            path.addQuadCurve(to: CGPoint(x: tl, y: 0), 
                               control: CGPoint(x: 0, y: 0))
        } else {
            path.addLine(to: CGPoint(x: 0, y: 0))
        }
        
        // Top right corner
        path.addLine(to: CGPoint(x: width - tr, y: 0))
        if tr != 0 {
            path.addQuadCurve(to: CGPoint(x: width, y: tr), 
                               control: CGPoint(x: width, y: 0))
        } else {
            path.addLine(to: CGPoint(x: width, y: 0))
        }
        
        // Bottom right corner
        path.addLine(to: CGPoint(x: width, y: height - br))
        if br != 0 {
            path.addQuadCurve(to: CGPoint(x: width - br, y: height), 
                               control: CGPoint(x: width, y: height))
        } else {
            path.addLine(to: CGPoint(x: width, y: height))
        }
        
        // Bottom left corner
        path.addLine(to: CGPoint(x: bl, y: height))
        if bl != 0 {
            path.addQuadCurve(to: CGPoint(x: 0, y: height - bl), 
                               control: CGPoint(x: 0, y: height))
        } else {
            path.addLine(to: CGPoint(x: 0, y: height))
        }
        
        path.closeSubpath()
        
        return path
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    CalendarNavigation(
        onPrevious: {},
        onToday: {},
        onNext: {}
    )
    .padding()
}
