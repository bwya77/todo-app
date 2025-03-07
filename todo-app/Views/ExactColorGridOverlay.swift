import SwiftUI

struct ExactColorGridOverlay: ViewModifier {
    let exactGridColor = Color(red: 245/255, green: 245/255, blue: 245/255)
    
    func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    // Horizontal lines
                    VStack(spacing: 60) {
                        ForEach(0..<24, id: \.self) { _ in
                            Rectangle()
                                .fill(exactGridColor)
                                .frame(height: 1)
                        }
                        Spacer()
                    }
                    
                    // Vertical lines
                    HStack(spacing: 0) {
                        ForEach(0..<8, id: \.self) { index in
                            Rectangle()
                                .fill(exactGridColor)
                                .frame(width: 1)
                            if index < 7 {
                                Spacer()
                            }
                        }
                    }
                }
            )
    }
}

extension View {
    func withExactColorGrid() -> some View {
        self.modifier(ExactColorGridOverlay())
    }
}
