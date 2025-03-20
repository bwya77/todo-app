//
//  ContentView.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/4/25.
//  Refactored according to improvement plan on 3/7/25.
//

import SwiftUI
import CoreData
import AppKit

#if DEBUG
import OSLog
#endif

// Custom ViewModifier to enforce background color
struct SidebarBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color(red: 248/255, green: 250/255, blue: 251/255))
            .compositingGroup() 
            .scrollContentBackground(.hidden)
    }
}

// Extension to handle scrolling behavior
extension NSScrollView {
    open override func scrollWheel(with event: NSEvent) {
        super.scrollWheel(with: event)
        // No longer hiding toolbar on scroll since we need it for the sidebar toggle
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

// Singleton toolbar delegate to handle toolbar actions
class ToolbarDelegate: NSObject, NSToolbarDelegate {
    static let shared = ToolbarDelegate()
    
    // Toolbar item identifiers
    private let toggleSidebarItemID = NSToolbarItem.Identifier("toggleSidebar")
    
    // Binding to update sidebar visibility
    var sidebarVisibilityBinding: Binding<Bool>? = nil
    
    // MARK: - NSToolbarDelegate
    
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        if itemIdentifier == toggleSidebarItemID {
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            
            // Set image based on current sidebar state
            let isVisible = sidebarVisibilityBinding?.wrappedValue ?? true
            let imageName = isVisible ? "sidebar.left" : "sidebar.right"
            let description = isVisible ? "Hide Sidebar" : "Show Sidebar"
            
            item.image = NSImage(systemSymbolName: imageName, accessibilityDescription: description)
            
            item.label = "Toggle Sidebar"
            item.paletteLabel = "Toggle Sidebar"
            item.toolTip = "Toggle Sidebar"
            item.target = self
            item.action = #selector(toggleSidebar)
            
            return item
        }
        
        return nil
    }
    
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [toggleSidebarItemID]
    }
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [toggleSidebarItemID]
    }
    
    // MARK: - Actions
    
    @objc func toggleSidebar() {
        // Toggle sidebar visibility
        guard let binding = sidebarVisibilityBinding else { return }
        
        // Toggle the state
        binding.wrappedValue.toggle()
        
        // Update toolbar button image
        if let window = NSApp.mainWindow,
           let toolbar = window.toolbar,
           let item = toolbar.items.first(where: { $0.itemIdentifier == toggleSidebarItemID }) {
            
            // Use the correct SF Symbol based on sidebar visibility state
            // "sidebar.left" when sidebar is visible (for hiding action)
            // "sidebar.right" when sidebar is hidden (for showing action)
            let imageName = binding.wrappedValue ? "sidebar.left" : "sidebar.right"
            let description = binding.wrappedValue ? "Hide Sidebar" : "Show Sidebar"
            
            item.image = NSImage(systemSymbolName: imageName, accessibilityDescription: description)
        }
        
        // Post notification for analytics or other observers
        NotificationCenter.default.post(
            name: Notification.Name("SidebarVisibilityChanged"),
            object: nil,
            userInfo: ["isVisible": binding.wrappedValue]
        )
    }
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedViewType: ViewType = .upcoming
    @State private var selectedProject: Project? = nil
    @State private var currentDate = Date()
    @State private var sidebarWidth: CGFloat = 250
    @State private var isSidebarVisible: Bool = true
    
    // States for the task popup
    @State private var showingAddTaskPopup = false
    @State private var animatePopup = false
    @State private var preselectedProject: Project? = nil
    
    // For debugging and testing
    #if DEBUG
    @State private var showProgressTest = false
    @State private var showDebugView = false
    #endif
    
    // Override the divider color for week view
    let weekGridColor = Color(red: 245/255, green: 245/255, blue: 245/255)
    
    var body: some View {
        ZStack {
            // Base background layer
            Color(red: 248/255, green: 250/255, blue: 251/255).ignoresSafeArea()
            
            HStack(spacing: 0) {
                // Main sidebar content with animation
                if isSidebarVisible {
                    // FIXED: Previously, this sidebar implementation had a jitter issue
                    // when transitioning from collapsed to expanded state.
                    // The solution includes:
                    // 1. Using a ZStack to contain both sidebar and resize handle
                    // 2. Applying opacity transition instead of move transition
                    // 3. Switching from spring to easeInOut animation
                    // 4. Ensuring stable positioning of elements during transition
                    ZStack(alignment: .trailing) {
                        SidebarView(
                            selectedViewType: $selectedViewType,
                            selectedProject: $selectedProject,
                            context: viewContext,
                            onShowTaskPopup: { showTaskPopup() }
                        )
                        .frame(width: sidebarWidth, alignment: .leading)
                        .modifier(SidebarBackgroundModifier())
                        
                        // Position resize handle at the trailing edge of sidebar
                        ResizeHandle { delta in
                            let newWidth = sidebarWidth + delta
                            // Constrain sidebar width between reasonable limits
                            if newWidth >= 180 && newWidth <= 400 {
                                sidebarWidth = newWidth
                            }
                        }
                        .frame(maxHeight: .infinity)
                    }
                    .frame(width: sidebarWidth, alignment: .leading)
                    .transition(.opacity) // Use opacity instead of move for smoother transition
                }
                
                // Main content area with layoutAnimation for smooth width adjustments
                // VStack with layoutPriority helps main content area resize smoothly without jittering
                // when sidebar appears/disappears
                VStack {
                    // Add the save order on navigation modifier
                    switch selectedViewType {
                    case .upcoming:
                    // Calendar view for upcoming tasks
                    UpcomingView()
                        .environment(\.managedObjectContext, viewContext)
                        .edgesIgnoringSafeArea(.bottom)
                        .background(Color.white)

                    case .inbox, .today, .filters, .completed, .project:
                    // Use the appropriate task list view based on feature flags
                    TaskListViewFactory.createTaskListView(
                        viewType: selectedViewType,
                        selectedProject: selectedProject,
                        context: viewContext
                    )
                    
                    // No more .addTask case since we're using a popup instead
                    }
                }
                .layoutPriority(1)
                .withSaveOrderOnNavigation() // Add the task order persistence modifier
            }
            .animation(.easeInOut(duration: 0.25), value: isSidebarVisible)
        }
        .onAppear {
            // Set up the toolbar for sidebar toggle when view appears
            setupToolbar()
            
            // Listen for notifications to show the add task popup with a pre-selected project
            NotificationCenter.default.addObserver(forName: NSNotification.Name("ShowAddTaskPopup"), object: nil, queue: .main) { notification in
                if let project = notification.userInfo?["project"] as? Project {
                    showTaskPopup(withProject: project)
                }
            }
            
            #if DEBUG
            // Register keyboard shortcut for testing
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.modifierFlags.contains(.command) && event.keyCode == 2 { // Command+D
                    self.showProgressTest.toggle()
                    return nil // Return nil to allow normal event processing
                } else if event.modifierFlags.contains(.command) && event.keyCode == 3 { // Command+F
                    self.showDebugView.toggle()
                    return nil
                }
                return event
            }
            #endif
        }
        .overlay {
            ZStack {
                if showingAddTaskPopup {
                    PopupBlurView(isPresented: animatePopup, onDismiss: closePopup) {
                        if animatePopup {
                            AddTaskPopup(taskViewModel: TaskViewModel(context: viewContext), selectedProject: preselectedProject)
                                .environment(\.managedObjectContext, viewContext)
                        }
                    }
                    .transition(.opacity)
                    .zIndex(100)
                    .edgesIgnoringSafeArea(.all)
                }
                
                #if DEBUG
                // Progress test view for development testing
                if showProgressTest {
                PopupBlurView(isPresented: showProgressTest, onDismiss: { showProgressTest = false }) {
                AnimatedProgressIndicatorTest()
                .frame(width: 500, height: 400)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 10)
                }
                .transition(.opacity)
                .zIndex(100)
                .edgesIgnoringSafeArea(.all)
                }
                
            // Debug task view for development testing
            if showDebugView {
                PopupBlurView(isPresented: showDebugView, onDismiss: { showDebugView = false }) {
                    DebugTaskView()
                        .frame(width: 500, height: 600)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 10)
                }
                .transition(.opacity)
                .zIndex(100)
                .edgesIgnoringSafeArea(.all)
            }
            #endif
            }
        }
    }
    
    // Show the task popup
    func showTaskPopup(withProject project: Project? = nil) {
        // Set the preselected project if provided
        self.preselectedProject = project
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            showingAddTaskPopup = true
            // Immediate animation looks better with scale effect
            animatePopup = true
        }
    }
    
    // Close popup with animation
    private func closePopup() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            animatePopup = false
            
            // Give it time to animate out before removing from view hierarchy
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showingAddTaskPopup = false
            }
        }
    }
    
    // Setup toolbar with toggle sidebar button
    private func setupToolbar() {
        // Use helper to get main window
        guard let window = NSApp.mainWindow else { return }
        
        // Create a toolbar if it doesn't exist
        if window.toolbar == nil {
            let toolbar = NSToolbar(identifier: "MainWindowToolbar")
            toolbar.displayMode = .iconOnly
            toolbar.allowsUserCustomization = false
            toolbar.autosavesConfiguration = true
            // Note: showsBaselineSeparator is deprecated in macOS 15.0
            // We'll achieve a similar effect using toolbarStyle instead
            #if swift(>=5.9) && canImport(AppKit)
            if #available(macOS 15.0, *) {
                // Use alternative approach for macOS 15+
            } else {
                toolbar.showsBaselineSeparator = false
            }
            #else
            toolbar.showsBaselineSeparator = false
            #endif
            toolbar.delegate = ToolbarDelegate.shared
            window.toolbar = toolbar
        }
        
        // Ensure toolbar is visible and has proper style
        window.toolbar?.isVisible = true
        window.toolbarStyle = .unifiedCompact
        
        // Set the toolbar style for a clean, modern appearance
        // This provides a similar effect to showsBaselineSeparator = false
        // and is the recommended approach for macOS
        
        // Register for sidebar toggle callbacks
        ToolbarDelegate.shared.sidebarVisibilityBinding = $isSidebarVisible
    }
}

// Helper extension to easily access the main window
extension NSApplication {
    var mainWindow: NSWindow? {
        return windows.first { $0.isKeyWindow } ?? windows.first
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
