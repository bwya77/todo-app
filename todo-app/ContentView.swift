import SwiftUI
import CoreData
import AppKit

// Custom ViewModifier to enforce background color
struct SidebarBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color(red: 248/255, green: 250/255, blue: 251/255))
            .compositingGroup() 
            .scrollContentBackground(.hidden)
    }
}

// Extension to prevent title bar appearance on scroll
extension NSScrollView {
    open override func scrollWheel(with event: NSEvent) {
        super.scrollWheel(with: event)
        NSApp.mainWindow?.toolbar?.isVisible = false
    }
}

// Resizable sidebar handle
struct ResizeHandle: View {
    let onDrag: (CGFloat) -> Void
    
    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: 10)
            .onHover { isHovered in
                if isHovered {
                    NSCursor.resizeLeftRight.push()
                } else {
                    NSCursor.pop()
                }
            }
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        onDrag(value.translation.width)
                    }
            )
    }
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedViewType: ViewType = .upcoming
    @State private var selectedProject: Project? = nil
    @State private var currentDate = Date()
    @State private var sidebarWidth: CGFloat = 250
    
    var body: some View {
        ZStack {
            // Base background layer
            Color(red: 248/255, green: 250/255, blue: 251/255).ignoresSafeArea()
            
            HStack(spacing: 0) {
                // Main sidebar content
                SidebarView(
                    selectedViewType: $selectedViewType,
                    selectedProject: $selectedProject,
                    context: viewContext
                )
                .frame(width: sidebarWidth, alignment: .leading)
                .modifier(SidebarBackgroundModifier())
                
                // Invisible resize handle
                ResizeHandle { delta in
                    let newWidth = sidebarWidth + delta
                    // Constrain sidebar width between reasonable limits
                    if newWidth >= 180 && newWidth <= 400 {
                        sidebarWidth = newWidth
                    }
                }
                .frame(maxHeight: .infinity)
                
                // Main content
                switch selectedViewType {
                case .upcoming:
                    // Calendar view for upcoming tasks
                    UpcomingView()
                        .environment(\.managedObjectContext, viewContext)
                        .edgesIgnoringSafeArea(.bottom)
                        .background(Color.white)

                case .inbox, .today, .filters, .completed, .project:
                    // List view for other views
                    TaskListView(
                        viewType: selectedViewType,
                        selectedProject: selectedProject,
                        context: viewContext
                    )
                    
                case .addTask:
                    // This case handles the Add Task view
                    Text("Add Task View")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.white)
                }
            }
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
