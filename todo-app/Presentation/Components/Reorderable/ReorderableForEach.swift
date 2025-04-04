//
//  ReorderableForEach.swift
//  todo-app
//
//  Created on 3/19/25.
//

import SwiftUI
import Foundation

/// A reorderable version of ForEach that supports drag and drop reordering
/// Based directly on the example implementation from the article for maximum compatibility
public struct ReorderableForEach<Item: Reorderable, Content: View, Preview: View>: View {
    
    // MARK: - Initializers
    
    /// Initialize with custom preview
    public init(
        _ items: [Item],
        active: Binding<Item?>,
        dropTarget: Binding<UUID?>,
        @ViewBuilder content: @escaping (Item) -> Content,
        @ViewBuilder preview: @escaping (Item) -> Preview,
        moveAction: @escaping (IndexSet, Int) -> Void
    ) {
        self.items = items
        self._active = active
        self._dropTargetId = dropTarget
        self.content = content
        self.preview = preview
        self.moveAction = moveAction
    }
    
    /// Initialize without custom preview
    public init(
        _ items: [Item],
        active: Binding<Item?>,
        dropTarget: Binding<UUID?>,
        @ViewBuilder content: @escaping (Item) -> Content,
        moveAction: @escaping (IndexSet, Int) -> Void
    ) where Preview == EmptyView {
        self.items = items
        self._active = active
        self._dropTargetId = dropTarget
        self.content = content
        self.preview = nil
        self.moveAction = moveAction
    }
    
    // MARK: - Properties
    
    @Binding 
    private var active: Item?

    @State
    private var hasChangedLocation = false
    
    @Binding
    private var dropTargetId: UUID?
    
    private let items: [Item]
    private let content: (Item) -> Content
    private let preview: ((Item) -> Preview)?
    private let moveAction: (IndexSet, Int) -> Void

    // MARK: - View Body
    
    public var body: some View {
        ForEach(items) { item in
            if let preview {
                contentView(for: item)
                    .onDrag {
                        dragData(for: item)
                    } preview: {
                        preview(item)
                    }
            } else {
                contentView(for: item)
                    .onDrag {
                        dragData(for: item)
                    }
            }
        }
    }
    
    // MARK: - Helper Methods

    private func contentView(for item: Item) -> some View {
        content(item)
            // Fade the dragged item and enhance the visual feedback with more subtle hints
            .opacity(active == item && hasChangedLocation ? 0.5 : 1)
            .scaleEffect(active == item && hasChangedLocation ? 1.02 : 1)
            .contentShape(Rectangle()) // Make entire area draggable
            .border(Color.accentColor.opacity(active == item && hasChangedLocation ? 0.3 : 0), width: 1)
            // Show a drop indicator line at the bottom when this is the drop target
            .overlay(alignment: .bottom) {
                if let itemId = item.id as? UUID, itemId == dropTargetId {
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(height: 2)
                        .padding(.horizontal, 4)
                }
            }
            .onDrop(
                of: [.text],
                delegate: ReorderableDragRelocateDelegate(
                    item: item,
                    items: items,
                    active: $active,
                    hasChangedLocation: $hasChangedLocation,
                    dropTargetId: $dropTargetId
                ) { from, to in
                    // Use a simple animation for better performance
                    withAnimation(.easeInOut(duration: 0.2)) {
                        moveAction(from, to)
                    }
                }
            )
    }
    
    private func dragData(for item: Item) -> NSItemProvider {
        print("👉 Started dragging: \(item.id)")
        active = item
        return NSItemProvider(object: "\(item.id)" as NSString)
    }
}

// MARK: - Container Extension

/// Extension to make any view a container for ReorderableForEach
public extension View {
    
    /// Adds necessary drop support for handling drag operations outside the list
    func reorderableForEachContainer<Item: Reorderable>(
        active: Binding<Item?>,
        dropTarget: Binding<UUID?>? = nil
    ) -> some View {
        // If a dropTarget binding is provided, use it; otherwise, use a dummy binding
        let targetBinding = dropTarget ?? Binding<UUID?>(get: { nil }, set: { _ in })
        return onDrop(of: [.text], delegate: ReorderableDropOutsideDelegate(active: active, dropTargetId: targetBinding))
    }
}
