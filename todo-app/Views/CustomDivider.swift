import SwiftUI

struct CustomDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color(red: 245/255, green: 245/255, blue: 245/255))
            .frame(height: 1) // For horizontal dividers
            .frame(width: 1) // For vertical dividers
    }
}

// Extension to help inspect color values
extension Color {
    var components: (red: CGFloat, green: CGFloat, blue: CGFloat, opacity: CGFloat) {
        #if canImport(UIKit)
        typealias NativeColor = UIColor
        #elseif canImport(AppKit)
        typealias NativeColor = NSColor
        #endif
        
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var o: CGFloat = 0
        
        let nativeColor = NativeColor(self)
        nativeColor.getRed(&r, green: &g, blue: &b, alpha: &o)
        
        return (r, g, b, o)
    }
}
