import SwiftUI
import AppKit

// This view puts a hard-coded color directly in the RGB values
struct DirectGridLineView: View {
    // Define divider color at compile time to be exactly 238,238,238
    static let GRID_COLOR = Color(nsColor: NSColor(calibratedRed: 238.0/255.0, 
                                                  green: 238.0/255.0, 
                                                  blue: 238.0/255.0, 
                                                  alpha: 1.0))
    
    let thickness: CGFloat
    
    init(thickness: CGFloat = 1.0) {
        self.thickness = thickness
    }
    
    var body: some View {
        Rectangle()
            .fill(DirectGridLineView.GRID_COLOR)
            .frame(height: thickness)
    }
}

struct DirectVerticalGridLine: View {
    let thickness: CGFloat
    
    init(thickness: CGFloat = 1.0) {
        self.thickness = thickness
    }
    
    var body: some View {
        Rectangle()
            .fill(DirectGridLineView.GRID_COLOR)
            .frame(width: thickness)
    }
}
