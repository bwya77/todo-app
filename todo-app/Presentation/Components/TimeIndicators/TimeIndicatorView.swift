import SwiftUI

struct TimeIndicatorView: View {
    @EnvironmentObject var positioner: TimeIndicatorPositioner
    
    private let calendar = Calendar.current
    
    // Add a small vertical offset to account for indicator height
    private let verticalOffset: CGFloat = -4
    
    var body: some View {
        GeometryReader { geometry in
            // Show current time on the indicator (unadjusted)
            let timeString = formatTime(positioner.currentTime)
            
            // But position the indicator where it would be 3 minutes earlier (day view)
            let offset = calculateOffset(for: positioner.currentTime.addingTimeInterval(-180), in: geometry.size.height)
            
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
                .offset(y: offset)
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter.string(from: date)
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
        return CGFloat(totalSeconds) * secondHeight + verticalOffset
    }
}
