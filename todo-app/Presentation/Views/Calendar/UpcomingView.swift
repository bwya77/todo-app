//
//  UpcomingView.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/4/25.
//  Refactored according to improvement plan on 3/7/25.
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
                
                // Header with animated month transition
                VStack(alignment: .leading, spacing: 12) {
                    Text("Upcoming")
                        .font(.system(size: 24, weight: .bold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .alignmentGuide(.leading) { d in d[.leading] }
                    
                    // Use our custom MonthHeaderView for animated month transitions
                    MonthHeaderView(visibleMonth: $visibleMonth)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
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
