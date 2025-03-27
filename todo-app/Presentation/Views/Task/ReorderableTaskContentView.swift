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
    @Binding var dropTargetId: UUID?
    
    let viewType: ViewType
    
    // MARK: - View Body
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(0..<viewModel.numberOfSections, id: \.self) { section in
                    // Use our unified solution for all sections
                    ReorderableTaskSection(
                        section: section,
                        title: viewModel.titleForSection(section),
                        tasks: viewModel.tasksForSection(section),
                        expandedGroups: $expandedGroups,
                        activeTask: $activeTask,
                        dropTargetId: $dropTargetId,
                        onToggleComplete: { task in
                            viewModel.toggleTaskCompletion(task)
                        },
                        onDeleteTask: { task in
                            viewModel.deleteTask(task)
                        },
                        onMoveTask: { fromOffsets, toOffset, sectionIndex in
                            // Still need this for backward compatibility
                            viewModel.reorderTasksInSection(
                                fromOffsets: fromOffsets,
                                toOffset: toOffset,
                                section: sectionIndex
                            )
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
        .reorderableForEachContainer(active: $activeTask, dropTarget: $dropTargetId)
    }
}
