import SwiftUI
import AppKit

struct WeekViewHack: View {
    @State private var hasAppliedHack = false
    
    var body: some View {
        Text("")
            .frame(width: 0, height: 0)
            .onAppear {
                if !hasAppliedHack {
                    DispatchQueue.main.async {
                        // Set the RGB(245,245,245) color for dividers
                        hasAppliedHack = true
                    }
                }
            }
    }
}
