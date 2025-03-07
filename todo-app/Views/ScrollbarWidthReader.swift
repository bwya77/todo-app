import SwiftUI
import Foundation

// A custom view modifier to handle scrollbar width detection
struct ScrollbarWidthModifier: ViewModifier {
    @Binding var scrollbarWidth: CGFloat
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        // NSScroller provides the system scrollbar width
                        DispatchQueue.main.async {
                            scrollbarWidth = NSScroller.scrollerWidth(for: .regular, scrollerStyle: .overlay)
                        }
                    }
            }
        }
    }
}

// Pre-built view to measure scrollbar width
struct ScrollbarWidthReader<Content: View>: View {
    @State private var scrollbarWidth: CGFloat = 0
    let content: ((CGFloat) -> Content)
    
    // Original binding-based initializer
    init(scrollbarWidth: Binding<CGFloat>, @ViewBuilder content: @escaping () -> Content) {
        self._scrollbarWidth = State(initialValue: scrollbarWidth.wrappedValue)
        self.content = { width in content() }
    }
    
    // New closure-based initializer that passes width to content
    init(@ViewBuilder content: @escaping (CGFloat) -> Content) {
        self.content = content
    }
    
    var body: some View {
        content(scrollbarWidth)
            .modifier(ScrollbarWidthModifier(scrollbarWidth: $scrollbarWidth))
    }
}

// Extension to make it easier to use
extension View {
    func measureScrollbarWidth(width: Binding<CGFloat>) -> some View {
        self.modifier(ScrollbarWidthModifier(scrollbarWidth: width))
    }
}
