//
//  UpcomingView.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/4/25.
//

import SwiftUI
import CoreData

struct UpcomingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedDate: Date? = Date()
    @State private var visibleMonth: Date = Date()
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Ensure the VStack takes full height
                Spacer().frame(height: 0)
                
                // Header - fixed height, reduced padding
                Text("Upcoming")
                .font(.system(size: 24, weight: .bold)) // Smaller font size
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 16) // Reduced top padding
                .padding(.bottom, 8) // Reduced bottom padding
                
                // Calendar - fills remaining space with CalendarKit implementation
                CalendarKitView(selectedDate: $selectedDate, visibleMonth: $visibleMonth)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Ensure we go to the bottom
                Spacer().frame(height: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            .background(Color.white)
        }
    }
}

#Preview {
    UpcomingView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
