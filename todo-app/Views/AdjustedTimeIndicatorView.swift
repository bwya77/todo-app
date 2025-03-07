import SwiftUI

struct AdjustedTimeIndicatorView: View {
    @EnvironmentObject var positioner: TimeIndicatorPositioner
    // Add a small vertical offset to account for indicator height
    // This ensures the red line is exactly at the hour mark, not the top of the indicator
    private let verticalOffset: CGFloat = -4
    
    // Add debug option, default to false
    var debug: Bool = false
    
    private let calendar = Calendar.current
    
    // Timer for forcing view updates
    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
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
                            let now = Date()
                            let hour = calendar.component(.hour, from: now)
                            let minute = calendar.component(.minute, from: now)
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
                // getOffset() already accounts for the 2-minute position adjustment
                .offset(y: positioner.getOffset() + verticalOffset)
            }
            .onReceive(timer) { _ in
                // Force view refresh
            }
        }
    }
    
    // Manual time string generation to ensure correct time display
    private var timeString: String {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now) % 12
        let hour12 = hour == 0 ? 12 : hour
        let minute = calendar.component(.minute, from: now)
        return "\(hour12):\(String(format: "%02d", minute))"      
    }
}
