import SwiftUI
import AppKit

// Special grid line view for weekend days with higher contrast
struct WeekendGridLineView: View {
    let thickness: CGFloat
    
    init(thickness: CGFloat = 1.0) {
        self.thickness = thickness
    }
    
    var body: some View {
        Rectangle()
            .fill(AppColors.weekendGridlineColor)
            .frame(height: thickness)
    }
}

struct WeekendVerticalGridLine: View {
    let thickness: CGFloat
    
    init(thickness: CGFloat = 1.0) {
        self.thickness = thickness
    }
    
    var body: some View {
        Rectangle()
            .fill(AppColors.weekendGridlineColor)
            .frame(width: thickness)
    }
}
