//
//  PopupBlurView.swift
//  todo-app
//
//  Created on 3/9/25.
//

import SwiftUI

struct PopupBlurView<Content: View>: View {
    var isPresented: Bool
    var content: () -> Content
    var onDismiss: (() -> Void)?
    
    init(isPresented: Bool, onDismiss: (() -> Void)? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.isPresented = isPresented
        self.content = content
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if isPresented {
                    // Background blur
                    Rectangle()
                        .fill(Color.black.opacity(0.3))
                        .edgesIgnoringSafeArea(.all)
                        .transition(.opacity)
                        .onTapGesture {
                            dismissPopup()
                        }
                    
                    // Content with centered position and scale animation
                    content()
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8, anchor: .center).combined(with: .opacity),
                            removal: .scale(scale: 0.9).combined(with: .opacity)
                        ))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isPresented)
        }
    }
    
    private func dismissPopup() {
        onDismiss?()
    }
}
