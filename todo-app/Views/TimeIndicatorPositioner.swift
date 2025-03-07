import SwiftUI

class TimeIndicatorPositioner: ObservableObject {
    // Singleton for shared positioning
    static let shared = TimeIndicatorPositioner()
    
    @Published var currentTime = Date()
    private var timer: Timer?
    
    // Offset multiplier (each hour is 60px)
    let hourHeight: CGFloat = 60
    
    init() {
        // Update time every minute
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.currentTime = Date()
            self?.objectWillChange.send()
        }
        timer?.fire() // Update immediately
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // Calculate offset based on current time
    func getOffset() -> CGFloat {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentTime)
        let minute = calendar.component(.minute, from: currentTime)
        
        // Convert to pixels (60px per hour, minute is fractional)
        return CGFloat(hour) * hourHeight + (CGFloat(minute) / 60.0) * hourHeight
    }
}
