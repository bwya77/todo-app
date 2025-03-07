import SwiftUI

class TimeIndicatorPositioner: ObservableObject {
    // Singleton for shared positioning
    static let shared = TimeIndicatorPositioner()
    
    @Published var currentTime = Date()
    private var timer: Timer?
    
    // Offset multiplier (each hour is 60px)
    let hourHeight: CGFloat = 60
    
    init() {
        // Set initial time immediately
        self.currentTime = Date()
        scheduleTimer()
    }
    
    private func scheduleTimer() {
        let now = Date()
        let calendar = Calendar.current
        let nextSecond = calendar.date(byAdding: .second, value: 1, to: now) ?? now.addingTimeInterval(1)
        
        timer = Timer(fire: nextSecond, interval: 1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.currentTime = Date()
            }
        }
        
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // Calculate offset based on current time
    func getOffset() -> CGFloat {
        let calendar = Calendar.current
        
        // For positioning only, subtract 5 minutes from the current time (week view)
        let positionTime = currentTime.addingTimeInterval(-300) // -300 seconds = -5 minutes
        
        let hour = calendar.component(.hour, from: positionTime)
        let minute = calendar.component(.minute, from: positionTime)
        let second = calendar.component(.second, from: positionTime)
        
        // Convert to pixels (60px per hour, minute and second are fractional)
        let minuteFraction = CGFloat(minute) / 60.0
        let secondFraction = CGFloat(second) / 3600.0
        return CGFloat(hour) * hourHeight + (minuteFraction + secondFraction) * hourHeight
    }
}
