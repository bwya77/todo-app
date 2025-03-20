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
        @ViewBuilder content: @escaping (Item) -> Content,
        @ViewBuilder preview: @escaping (Item) -> Preview,
        moveAction: @escaping (IndexSet, Int) -> Void
    ) {
        self.items = items
        self._active = active
        self.content = content
        self.preview = preview
        self.moveAction = moveAction
    }
    
    /// Initialize without custom preview
    public init(
        _ items: [Item],
        active: Binding<Item?>,
        @ViewBuilder content: @escaping (Item) -> Content,
        moveAction: @escaping (IndexSet, Int) -> Void
    ) where Preview == EmptyView {
        self.items = items
        self._active = active
        self.content = content
        self.preview = nil
        self.moveAction = moveAction
    }
    
    // MARK: - Properties
    
    @Binding 
    private var active: Item?

    @State
    private var hasChangedLocation = false
    
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
            .opacity(active == item && hasChangedLocation ? 0.7 : 1)
            .contentShape(Rectangle()) // Make entire area draggable
            .onDrop(
                of: [.text],
                delegate: ReorderableDragRelocateDelegate(
                    item: item,
                    items: items,
                    active: $active,
                    hasChangedLocation: $hasChangedLocation
                ) { from, to in
                    // Use spring animation for smoother sliding effect
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.3)) {
                        moveAction(from, to)
                    }
                    
                    // Force any context saves
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ForceContextSave"),
                        object: nil
                    )
                }
            )
    }
    
    private func dragData(for item: Item) -> NSItemProvider {
        active = item
        return NSItemProvider(object: "\(item.id)" as NSString)
    }
}

// MARK: - Container Extension

/// Extension to make any view a container for ReorderableForEach
public extension View {
    
    /// Adds necessary drop support for handling drag operations outside the list
    func reorderableForEachContainer<Item: Reorderable>(
        active: Binding<Item?>
    ) -> some View {
        onDrop(of: [.text], delegate: ReorderableDropOutsideDelegate(active: active))
    }
}
