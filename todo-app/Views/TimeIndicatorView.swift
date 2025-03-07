import SwiftUI

struct TimeIndicatorView: View {
    @EnvironmentObject var positioner: TimeIndicatorPositioner
    
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
                .offset(y: positioner.getOffset())
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter.string(from: date)
    }
}
