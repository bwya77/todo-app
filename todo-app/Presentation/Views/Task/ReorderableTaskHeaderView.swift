//
//  ReorderableTaskHeaderView.swift
//  todo-app
//
//  Created on 3/19/25.
//

import SwiftUI

/// Header view for the reorderable task list
struct ReorderableTaskHeaderView: View {
    // MARK: - Properties
    
    let title: String
    var onReset: (() -> Void)? = nil
    
    // MARK: - View Body
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 24, weight: .bold))
            
            Spacer()
            
            // Add reset button only if we have a reset action
            if let onReset = onReset {
                Button(action: onReset) {
                    Label("Reset Order", systemImage: "arrow.triangle.2.circlepath")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Reset task ordering if it becomes corrupted")
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 28)
        .padding(.bottom, 8)
    }
}
