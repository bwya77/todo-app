import SwiftUI

struct ShadowDivider: View {
    var body: some View {
        ZStack {
            // Main divider
            Rectangle()
                .fill(Color.black.opacity(0.1))
                .frame(height: 1)
                
            // More subtle shadow effect
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 1)
                Rectangle()
                    .fill(Color.black.opacity(0.03))
                    .frame(height: 1)
                Rectangle()
                    .fill(Color.black.opacity(0.01))
                    .frame(height: 1)
            }
        }
    }
}
