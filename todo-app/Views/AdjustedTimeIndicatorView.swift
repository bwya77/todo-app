import SwiftUI

struct AdjustedTimeIndicatorView: View {
    @EnvironmentObject var positioner: TimeIndicatorPositioner
    
    // Add a small vertical offset to account for indicator height
    // This ensures the red line is exactly at the hour mark, not the top of the indicator
    private let verticalOffset: CGFloat = -4
    
    // Add debug option, default to false
    var debug: Bool = false
    
    private let calendar = Calendar.current
    
    var body: some View {
        // Get the updated time from the positioner
        let timeString = formatTime(positioner.currentTime)
        
        // Position at the correct time
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                // Empty spacer to fill the container
                Color.clear
                
                // Time indicator at calculated position
                HStack(spacing: 0) {
                    // Red capsule indicator
                    Group {
                        if debug {
                            // In debug mode, show hour and minutes separately
                            let hour = calendar.component(.hour, from: positioner.currentTime)
                            let minute = calendar.component(.minute, from: positioner.currentTime)
                            Text("\(hour):\(String(format: "%02d", minute))")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(Color.blue.opacity(0.9)) // Blue in debug mode
                                )
                        } else {
                            // Normal mode
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
                        }
                    }
                    
                    // Red line extending to the right
                    Rectangle()
                        .fill(debug ? Color.blue : Color.red)
                        .frame(height: 2)
                }
                .frame(width: geometry.size.width, alignment: .leading)
                .offset(y: positioner.getOffset() + verticalOffset)
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter.string(from: date)
    }
}
