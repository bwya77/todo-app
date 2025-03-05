//
//  ContentView.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/4/25.
//

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

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedViewType: ViewType = .upcoming
    @State private var selectedProject: Project? = nil
    @State private var currentDate = Date()
    
    var body: some View {
        ZStack {
            // Base background layer
            Color(red: 248/255, green: 250/255, blue: 251/255).edgesIgnoringSafeArea(.all)
            
            HStack(spacing: 0) {
                // Sidebar
                SidebarView(
                    selectedViewType: $selectedViewType,
                    selectedProject: $selectedProject,
                    context: viewContext
                )
                .frame(width: 250, alignment: .leading)
                .modifier(SidebarBackgroundModifier())
                
                // Main content
                switch selectedViewType {
                case .upcoming:
                    // Calendar view for upcoming tasks
                    UpcomingView()
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
