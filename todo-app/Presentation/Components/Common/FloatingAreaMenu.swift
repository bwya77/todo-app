//
//  FloatingAreaMenu.swift
//  todo-app
//
//  Created on 3/26/25.
//

import SwiftUI

struct FloatingMenuItem: Identifiable {
    var id = UUID()
    var title: String
    var icon: String
    var color: Color = .primary
    var action: () -> Void
}

struct FloatingAreaMenu: View {
    var items: [FloatingMenuItem]
    @Binding var isPresented: Bool
    var position: CGPoint
    
    @State private var hoverIndex: Int? = nil
    
    var body: some View {
        if isPresented {
            VStack(spacing: 8) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    if index > 0 && (index == items.count - 1) {
                        Divider().padding(.horizontal, 8)
                    }
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isPresented = false
                        }
                        // Delay the action slightly to allow animation to complete
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            item.action()
                        }
                    }) {
                        HStack {
                            Image(systemName: item.icon)
                                .font(.system(size: 13))
                                .foregroundColor(item.color)
                                .frame(width: 22, alignment: .center)
                            
                            Text(item.title)
                                .font(.system(size: 13))
                                .foregroundColor(item.color)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(hoverIndex == index ? Color.gray.opacity(0.15) : Color.clear)
                        )
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .onHover { isHovered in
                        withAnimation(.easeInOut(duration: 0.1)) {
                            hoverIndex = isHovered ? index : nil
                        }
                    }
                }
            }
            .padding(.vertical, 8)
            .frame(width: 180)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 2)
            )
            .offset(x: -170, y: 20) // Position menu closer to the ellipsis
            .position(x: position.x, y: position.y)
            .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .top)))
            .zIndex(1000)
            .onAppear {
                // Add a tap gesture to the window to dismiss the menu
                NotificationCenter.default.addObserver(forName: NSNotification.Name("DismissFloatingMenus"), object: nil, queue: .main) { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                }
            }
        }
    }
}

// Global event monitor to detect clicks outside the menu
class FloatingMenuEventMonitor {
    static let shared = FloatingMenuEventMonitor()
    
    private var monitor: Any?
    private var localMonitor: Any?
    
    func startMonitoring() {
        guard monitor == nil else { return }
        
        // Monitor both global events (mouse clicks anywhere on screen)
        // and local events (mouse clicks in the app window)
        monitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.dismissAllMenus()
        }
        
        // Also monitor local mouse events (within the app)
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { event in
            self.dismissAllMenus()
            return event
        }
    }
    
    func stopMonitoring() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
        
        if let localMonitor = localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
    }
    
    func dismissAllMenus() {
        NotificationCenter.default.post(name: NSNotification.Name("DismissFloatingMenus"), object: nil)
    }
    
    deinit {
        stopMonitoring()
    }
}
