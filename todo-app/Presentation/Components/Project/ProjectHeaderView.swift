//
//  ProjectHeaderView.swift
//  todo-app
//
//  Created on 3/26/25.
//

import SwiftUI
import CoreData

struct ProjectHeaderView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var header: ProjectHeader
    @Binding var expandedHeaders: Set<UUID>
    
    // Computed property to get active task count
    private var activeTaskCount: Int {
        // Filter to count only incomplete tasks
        return header.tasks().filter { !$0.completed }.count
    }
    
    // Check if this header is expanded
    private var isExpanded: Bool {
        guard let headerId = header.id else { return true }
        return expandedHeaders.contains(headerId)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                // Expand/collapse button
                Button(action: toggleExpand) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .frame(width: 14, height: 14)
                }
                .buttonStyle(.plain)
                
                // Header title
                Text(header.title ?? "Untitled Header")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.getColor(from: header.project?.color ?? "gray"))
                
                Spacer()
                
                // Task count badge (only show if there are active tasks)
                if activeTaskCount > 0 {
                    Text("\(activeTaskCount)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppColors.getColor(from: header.project?.color ?? "gray"))
                        )
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            
            // Grey divider line added underneath the header
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
                .padding(.top, 2)
                .padding(.bottom, 2)
        }
    }
    
    // Toggle expand/collapse
    private func toggleExpand() {
        guard let headerId = header.id else { return }
        
        withAnimation(.easeInOut(duration: 0.2)) {
            if expandedHeaders.contains(headerId) {
                expandedHeaders.remove(headerId)
            } else {
                expandedHeaders.insert(headerId)
            }
        }
    }
}
