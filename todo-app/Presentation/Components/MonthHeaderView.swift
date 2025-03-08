//
//  MonthHeaderView.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/8/25.
//  Updated by Bradley Wyatt on 3/8/25 - Improved visual style with unified month/year display.
//
/// A custom header view for displaying the current month and year with different styling.
/// This component displays both the month and year in small text, with the month in a semibold font
/// and the year in a thinner font for improved visual hierarchy. The entire date is animated
/// as a single unit when transitioning between different months/years.

import SwiftUI

struct MonthHeaderView: View {
    // Input binding for the visible month
    @Binding var visibleMonth: Date
    
    // State to track month changes
    @State private var previousMonthNum: Int = 0
    @State private var currentMonthNum: Int = 0
    @State private var monthText: String = ""  // Month string
    @State private var yearText: String = ""   // Year string
    
    // Formatters
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"  // Only month
        return formatter
    }()
    
    private let yearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"  // Only year
        return formatter
    }()
    
    var body: some View {
        // Use a custom animator for the combined month and year
        CustomDateAnimator(month: monthText, year: yearText, height: 20, duration: 0.2) // Adjusted duration
            .frame(maxWidth: .infinity, alignment: .leading)
            .alignmentGuide(.leading) { d in d[.leading] }
            .padding(.leading, 0) // Ensure no leading padding
            .onChange(of: visibleMonth) { oldValue, newValue in
                // Check if the month or year has changed
                let oldMonth = Calendar.current.component(.month, from: oldValue)
                let oldYear = Calendar.current.component(.year, from: oldValue)
                let newMonth = Calendar.current.component(.month, from: newValue)
                let newYear = Calendar.current.component(.year, from: newValue)
                
                // Only update if either the month or year has changed
                if oldMonth != newMonth || oldYear != newYear {
                    // Store values for comparison
                    previousMonthNum = oldMonth
                    currentMonthNum = newMonth
                    
                    // Set month and year separately
                    monthText = monthFormatter.string(from: newValue)
                    yearText = yearFormatter.string(from: newValue)
                }
            }
            .onAppear {
                // Initialize with the current date values
                let calendar = Calendar.current
                currentMonthNum = calendar.component(.month, from: visibleMonth)
                previousMonthNum = currentMonthNum
                
                // Set initial month and year
                monthText = monthFormatter.string(from: visibleMonth)
                yearText = yearFormatter.string(from: visibleMonth)
            }
    }
}

/// A custom animator specifically for month/year transitions with different styling
struct CustomDateAnimator: View {
    let month: String
    let year: String
    let height: CGFloat
    let duration: Double
    
    @State private var hasAppeared = false
    @State private var animationKey = UUID().uuidString
    
    var body: some View {
        HStack(spacing: 6) {
            Text(month)
                .font(.system(size: 14, weight: .semibold))
            
            Text(year)
                .font(.system(size: 14, weight: .thin))
        }
        .offset(y: hasAppeared ? 0 : height)
        .opacity(hasAppeared ? 1 : 0)
        .animation(.easeInOut(duration: duration), value: hasAppeared) // Using shorter duration
        .id("\(month)\(year)_\(animationKey)") // Force view recreation when text changes
        .onAppear {
            // Start animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { // Shorter delay
                hasAppeared = true
            }
        }
        .onChange(of: month) { _, _ in
            // Reset animation state and generate new ID to force recreation
            hasAppeared = false
            animationKey = UUID().uuidString
            
            // Restart animation after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { // Shorter delay
                hasAppeared = true
            }
        }
        .onChange(of: year) { _, _ in
            // Reset animation state and generate new ID to force recreation
            hasAppeared = false
            animationKey = UUID().uuidString
            
            // Restart animation after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { // Shorter delay
                hasAppeared = true
            }
        }
    }
}

#Preview("Month Header") {
    VStack(spacing: 20) {
        // Current date
        MonthHeaderView(visibleMonth: .constant(Date()))
        
        // Custom date - January 2025
        let januaryDate = Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        MonthHeaderView(visibleMonth: .constant(januaryDate))
        
        // Custom date - December 2025
        let decemberDate = Calendar.current.date(from: DateComponents(year: 2025, month: 12, day: 1))!
        MonthHeaderView(visibleMonth: .constant(decemberDate))
    }
    .padding()
}
