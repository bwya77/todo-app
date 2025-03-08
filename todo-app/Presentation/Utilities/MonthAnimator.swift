//
//  MonthAnimator.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/8/25.
//  Custom implementation for month transition animations
//

import SwiftUI

/// A custom text animator specifically for month transitions
struct MonthAnimator: View {
    let text: String
    let animateByCharacter: Bool
    let height: CGFloat
    let duration: Double
    let delayFactor: Double
    
    @State private var hasAppeared = false
    @State private var animationKey = UUID().uuidString
    
    init(
        text: String,
        animateByCharacter: Bool = false,
        height: CGFloat = 30,
        duration: Double = 0.3,  // Faster default duration
        delayFactor: Double = 0.04
    ) {
        self.text = text
        self.animateByCharacter = animateByCharacter
        self.height = height
        self.duration = duration
        self.delayFactor = delayFactor
    }
    
    var body: some View {
        Group {
            if animateByCharacter {
                // Character-by-character animation
                HStack(spacing: 0) {
                    ForEach(Array(text.enumerated()), id: \.offset) { index, character in
                        Text(String(character))
                            .offset(y: hasAppeared ? 0 : height)
                            .opacity(hasAppeared ? 1 : 0)
                            .animation(
                                .easeInOut(duration: duration)
                                .delay(Double(index) * delayFactor),
                                value: hasAppeared
                            )
                    }
                }
            } else {
                // Word-based animation (entire text as one unit)
                Text(text)
                    .offset(y: hasAppeared ? 0 : height)
                    .opacity(hasAppeared ? 1 : 0)
                    .animation(.easeInOut(duration: duration), value: hasAppeared)
            }
        }
        .id("\(text)_\(animationKey)") // Force view recreation when text changes
        .onAppear {
            // Start animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                hasAppeared = true
            }
        }
        .onChange(of: text) { _, _ in
            // Reset animation state and generate new ID to force recreation
            hasAppeared = false
            animationKey = UUID().uuidString
            
            // Restart animation after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                hasAppeared = true
            }
        }
    }
}

/// Preview for MonthAnimator
struct MonthAnimatorPreview: View {
    @State private var currentMonth = "January"
    @State private var byCharacter = false
    
    let months = ["January", "February", "March", "April", "May", "June",
                  "July", "August", "September", "October", "November", "December"]
    @State private var index = 0
    
    var body: some View {
        VStack(spacing: 40) {
            MonthAnimator(
                text: currentMonth,
                animateByCharacter: byCharacter,
                height: 30,
                duration: 0.5
            )
            .font(.system(size: 32, weight: .bold))
            .frame(height: 50)
            
            HStack(spacing: 20) {
                Button("Next Month") {
                    index = (index + 1) % months.count
                    currentMonth = months[index]
                }
                .buttonStyle(.borderedProminent)
                
                Toggle("Character Animation", isOn: $byCharacter)
                    .toggleStyle(.switch)
            }
        }
        .padding()
    }
}

#Preview {
    MonthAnimatorPreview()
}
