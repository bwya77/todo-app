//
//  AnimatedTextView.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/8/25.
//

import SwiftUI

/// A text animation implementation that provides a similar effect to the AnimateText library
struct AnimatedTextView: View {
    let text: String
    let height: CGFloat
    let duration: Double
    let delayFactor: Double
    
    @State private var hasAppeared = false
    @State private var previousText: String = ""
    @State private var isAnimating = false
    
    init(
        text: String, 
        height: CGFloat = 25, 
        duration: Double = 0.4, 
        delayFactor: Double = 0.04
    ) {
        self.text = text
        self.height = height
        self.duration = duration
        self.delayFactor = delayFactor
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // For simplicity, we'll animate the whole word rather than each character
            // This is similar to the word-based animation in AnimateText
            Text(text)
                .offset(y: isAnimating ? 0 : height)
                .opacity(isAnimating ? 1 : 0)
                .animation(.easeInOut(duration: duration), value: isAnimating)
                .id(text) // Ensure view is recreated when text changes
        }
        .onChange(of: text) { oldValue, newValue in
            if oldValue != newValue {
                // Reset animation state
                isAnimating = false
                
                // Trigger animation after a brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation(.easeInOut(duration: duration)) {
                        isAnimating = true
                    }
                }
            }
        }
        .onAppear {
            // Initial animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: duration)) {
                    isAnimating = true
                }
            }
        }
    }
}

/// Effect types that can be used for text animation
enum AnimatedTextEffect {
    case bottomToTop(height: CGFloat, duration: Double, delayFactor: Double)
    
    static func monthTransition(duration: Double = 0.5) -> AnimatedTextEffect {
        return .bottomToTop(height: 30, duration: duration, delayFactor: 0.04)
    }
}

/// Preview for AnimatedTextView
struct AnimatedTextViewPreview: View {
    @State private var currentText = "January"
    @State private var months = [
        "January", "February", "March", "April", 
        "May", "June", "July", "August",
        "September", "October", "November", "December"
    ]
    @State private var currentIndex = 0
    
    var body: some View {
        VStack(spacing: 40) {
            AnimatedTextView(text: currentText)
                .font(.system(size: 32, weight: .bold))
            
            Button("Change Month") {
                currentIndex = (currentIndex + 1) % months.count
                currentText = months[currentIndex]
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    AnimatedTextViewPreview()
}
