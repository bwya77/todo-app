//
//  AreaRowView.swift
//  todo-app
//
//  Created on 3/22/25.
//

import SwiftUI
import CoreData

/// A simple row view for areas in the list
public struct AreaRowView: View {
    let area: Area
    let isSelected: Bool
    
    @Environment(\.managedObjectContext) private var viewContext
    
    public init(area: Area, isSelected: Bool = false) {
        self.area = area
        self.isSelected = isSelected
    }
    
    public var body: some View {
        HStack(spacing: 10) {
            // Area icon
            Image(systemName: "cube.fill")
                .font(.system(size: 14))
                .foregroundColor(AppColors.getColor(from: area.color ?? "gray"))
            
            // Area name
            Text(area.name ?? "Unnamed Area")
                .lineLimit(1)
                .foregroundStyle(isSelected ? AppColors.selectedTextColor : .black)
                .font(.system(size: 14))
            
            Spacer()
            
            // Project count badge
            if area.totalTaskCount > 0 {
                Text("\(area.totalTaskCount)")
                    .foregroundColor(isSelected ? AppColors.selectedTextColor : .secondary)
                    .font(.system(size: 14))
            }
        }
    }
}
