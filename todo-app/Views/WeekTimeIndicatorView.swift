import SwiftUI

struct WeekTimeIndicatorView: View {
    @EnvironmentObject var positioner: TimeIndicatorPositioner
    // Add a small vertical offset to account for indicator height
    private let verticalOffset: CGFloat = -4
    
    // Specific adjustment for week view
    private let weekViewAdjustment: CGFloat = -5
    
    private let calendar = Calendar.current
    
    // Timer for forcing view updates
    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            // Position at the correct time
            ZStack(alignment: .topLeading) {
                // Empty spacer to fill the container
                Color.clear
                
                // Time indicator at calculated position
                HStack(spacing: 0) {
                    // Red capsule indicator
                    Text(timeString)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.red.opacity(0.9))
                        )
                    
                    // Red line extending to the right
                    Rectangle()
                        .fill(Color.red)
                        .frame(height: 2)
                }
                .frame(width: geometry.size.width, alignment: .leading)
                .offset(y: calculateOffset(for: positioner.currentTime.addingTimeInterval(-90), in: geometry.size.height)) // 1.5 minutes earlier for week view
            }
            .onReceive(timer) { _ in
                // Force view refresh
            }
        }
    }
    
    // Current time display (not adjusted for position)
    private var timeString: String {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now) % 12
        let hour12 = hour == 0 ? 12 : hour
        let minute = calendar.component(.minute, from: now)
        return "\(hour12):\(String(format: "%02d", minute))"      
    }
    
    private func calculateOffset(for date: Date, in height: CGFloat) -> CGFloat {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let second = calendar.component(.second, from: date)
        
        // Calculate the total number of seconds since the start of the day
        let totalSeconds = hour * 3600 + minute * 60 + second
        
        // Calculate the height of each second in the box
        let secondHeight = height / 86400.0 // 86400 seconds in a day
        
        // Calculate the offset based on the total number of seconds
        // Add the week view specific adjustment (2 ticks later)
        return CGFloat(totalSeconds) * secondHeight + verticalOffset + weekViewAdjustment
    }
}
