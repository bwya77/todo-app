# Reorderable Components

This module adds drag-and-drop reordering capability to lazy grids and stacks in SwiftUI, which is missing in the standard library.

## Components

1. **Reorderable.swift**: Defines the protocol for items that can be reordered.
2. **ReorderableForEach.swift**: Replacement for ForEach that enables drag reordering.
3. **ReorderableDelegates.swift**: Drop delegates that handle the reordering logic.

## Usage

### Basic Usage

Replace standard `ForEach` with `ReorderableForEach`:

```swift
@State private var activeItem: Item?
@State private var items: [Item] = [...]

var body: some View {
    LazyVStack {
        ReorderableForEach(items, active: $activeItem) { item in
            // Your normal row content
            Text("\(item.title)")
        } moveAction: { fromOffsets, toOffset in
            items.move(fromOffsets: fromOffsets, toOffset: toOffset)
        }
    }
    .reorderableForEachContainer(active: $activeItem)
}
```

### With Custom Preview

```swift
ReorderableForEach(items, active: $activeItem) { item in
    // Normal content
    Text("\(item.title)")
} preview: { item in
    // Preview when dragging
    Text("\(item.title)")
        .padding()
        .background(Color.blue)
        .foregroundColor(.white)
} moveAction: { fromOffsets, toOffset in
    items.move(fromOffsets: fromOffsets, toOffset: toOffset)
}
```

### Important Notes

1. Always add `.reorderableForEachContainer(active: $activeItem)` to the parent container.
2. For proper preview shape, add `.contentShape(.dragPreview, RoundedRectangle(cornerRadius: 10))` to the content.
3. Make sure your model conforms to `Identifiable` and `Equatable`.

## Integration with CoreData

When using with CoreData, update the display order in the database after reordering:

```swift
ReorderableForEach(tasks, active: $activeTask) { task in
    TaskRow(task: task)
} moveAction: { fromOffsets, toOffset in
    // Update view model
    viewModel.moveTasksInSection(fromOffsets: fromOffsets, toOffset: toOffset, section: sectionIndex)
}
```
