//
//  ReorderableTaskContentView.swift
//  todo-app
//
//  Created on 3/19/25.
//

import SwiftUI
import CoreData

/// Content view for the reorderable task list
struct ReorderableTaskContentView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: EnhancedTaskViewModel
    @Binding var expandedGroups: Set<String>
    @Binding var activeTask: Item?
    
    let viewType: ViewType
    
    // MARK: - View Body
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(0..<viewModel.numberOfSections, id: \.self) { section in
                    ReorderableTaskSection(
                        section: section,
                        title: viewModel.titleForSection(section),
                        tasks: viewModel.tasksForSection(section),
                        expandedGroups: $expandedGroups,
                        activeTask: $activeTask,
                        onToggleComplete: { task in
                            viewModel.toggleTaskCompletion(task)
                        },
                        onDeleteTask: { task in
                            viewModel.deleteTask(task)
                        },
                        onMoveTask: { fromOffsets, toOffset, sectionIndex in
                            // Use direct reordering to ensure proper save
                            viewModel.reorderTasksInSection(
                                fromOffsets: fromOffsets,
                                toOffset: toOffset,
                                section: sectionIndex
                            )
                            
                            // Double-save attempt after a delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                // Force context save
                                NotificationCenter.default.post(
                                    name: NSNotification.Name("ForceContextSave"),
                                    object: nil
                                )
                                
                                // Re-fetch data for display
                                viewModel.refreshFetch()
                            }
                        },
                        viewType: viewType
                    )
                    
                    // Add a small spacing between sections
                    if section < viewModel.numberOfSections - 1 {
                        Spacer().frame(height: 12)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .background(Color.white)
        // Add the reorderable container modifier to the scroll view
        .reorderableForEachContainer(active: $activeTask)
    }
}
