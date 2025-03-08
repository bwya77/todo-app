//
//  AnimatedMonthTest.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/8/25.
//

import SwiftUI

/// A test view to showcase our custom MonthAnimator
struct AnimatedMonthTest: View {
    @State private var currentMonthName: String = "January"
    @State private var currentYearString: String = "2025"
    @State private var animateByCharacter: Bool = false
    
    // Test months to cycle through
    private let months = [
        "January", "February", "March", "April", 
        "May", "June", "July", "August",
        "September", "October", "November", "December"
    ]
    
    // Current month index
    @State private var monthIndex = 0
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Month Animation Test")
                .font(.headline)
            
            // Display the month with our custom animator
            HStack(spacing: 8) {
                MonthAnimator(
                    text: currentMonthName,
                    animateByCharacter: animateByCharacter,
                    height: 30,
                    duration: 0.3
                )
                .font(.system(size: 32, weight: .bold))
                
                MonthAnimator(
                    text: currentYearString,
                    animateByCharacter: animateByCharacter,
                    height: 30,
                    duration: 0.3
                )
                .font(.system(size: 32, weight: .bold))
            }
            .frame(height: 50)
            
            HStack(spacing: 20) {
                // Test button to cycle through months
                Button("Next Month") {
                    // Increment month index and wrap around if needed
                    monthIndex = (monthIndex + 1) % months.count
                    
                    // Update displayed month
                    currentMonthName = months[monthIndex]
                    
                    // Occasionally update the year too
                    if monthIndex == 0 {
                        let currentYear = Int(currentYearString) ?? 2025
                        currentYearString = String(currentYear + 1)
                    }
                }
                .buttonStyle(.borderedProminent)
                
                // Toggle between word and character animation
                Toggle("Character Animation", isOn: $animateByCharacter)
                    .toggleStyle(.switch)
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}

#Preview {
    AnimatedMonthTest()
}
