//
//  FixedTimeIndicator.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/5/25.
//

import SwiftUI

// This is a specialized component that shows the current time line
// on a 24-hour vertical scale where each hour is 60px tall
struct FixedTimeIndicator: View {
    // Get the latest time
    @State private var currentTime = Date()
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    private let calendar = Calendar.current
    
    // Calculate current hour and minute
    private var hourAndMinute: (hour: Int, minute: Int) {
        return (
            calendar.component(.hour, from: currentTime),
            calendar.component(.minute, from: currentTime)
        )
    }
    
    // Calculate the offset based on the current time
    // Each hour block is 60px tall in the day view
    private var timeOffset: CGFloat {
        let (hour, minute) = hourAndMinute
        return CGFloat(hour * 60 + minute)
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: currentTime)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Used to position at the top
            Spacer()
                .frame(height: timeOffset)
            
            // Time indicator with line
            HStack(spacing: 0) {
                // Red capsule with time
                Text(timeString)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.red)
                    )
                
                // Red line extending to the right
                Rectangle()
                    .fill(Color.red)
                    .frame(height: 2)
            }
            
            // Fill remaining space
            Spacer()
        }
        .onReceive(timer) { _ in
            // Update the time every minute
            currentTime = Date()
        }
    }
}
