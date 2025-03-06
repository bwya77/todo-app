//
//  CalendarKitView.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/5/25.
//

import SwiftUI
import CoreData
import EventKit
import AppKit
// Import our custom components

// Main Calendar View implementation
struct CalendarKitView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var selectedDate: Date?
    @Binding var visibleMonth: Date
    
    // State for visible month and date range
    @State private var displayMode: CalendarDisplayMode = .month
    
    // Define notification name as a static constant for consistency
    static let switchToDayViewNotification = NSNotification.Name("SwitchToDayView")
    @State private var tasks: [Item] = []
    
    // Constants
    private let calendar = Calendar.current
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    enum CalendarDisplayMode {
        case month, week, day
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Ensures VStack takes all available space
            Spacer().frame(height: 0)
            // Calendar header with navigation
            HStack(spacing: 16) {
                Text(monthFormatter.string(from: visibleMonth))
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Mode selection
                Picker("View", selection: $displayMode) {
                    Text("Month").tag(CalendarDisplayMode.month)
                    Text("Week").tag(CalendarDisplayMode.week)
                    Text("Day").tag(CalendarDisplayMode.day)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 250)
                .padding(.horizontal, 12)
                
                Spacer()
                
                // Custom navigation buttons
                CalendarNavigation(
                    onPrevious: navigateToPrevious,
                    onToday: navigateToToday,
                    onNext: navigateToNext
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Calendar view based on display mode
            switch displayMode {
            case .month:
                // Use the WheelScrollableView for month view to enable trackpad/mouse wheel scrolling
                WheelScrollableView(
                    visibleMonth: $visibleMonth,
                    childContent: AnyView(
                        MonthCalendarView(
                            visibleMonth: $visibleMonth,
                            selectedDate: $selectedDate,
                            tasks: tasks
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    )
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
            case .week:
                WeekCalendarView(
                    visibleMonth: $visibleMonth,
                    selectedDate: $selectedDate,
                    tasks: tasks
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .day:
                DayCalendarView(
                    selectedDate: $selectedDate,
                    tasks: tasks
                )
                .environmentObject(TimeIndicatorPositioner.shared)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // No bottom spacer, to allow grid to extend to bottom
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            loadTasks()
            
            // Set up the notification observer for double-clicks
            NotificationCenter.default.addObserver(
                forName: CalendarKitView.switchToDayViewNotification,
                object: nil,
                queue: .main
            ) { notification in
                // Switch to day view for the currently selected date
                if let date = selectedDate {
                    visibleMonth = date
                    displayMode = .day
                }
            }
        }
        .onChange(of: visibleMonth) { oldValue, newValue in
            loadTasks()
        }
        .onChange(of: displayMode) { oldValue, newValue in
            loadTasks()
        }
    }
    
    private func navigateToPrevious() {
        switch displayMode {
        case .month:
            visibleMonth = calendar.date(byAdding: .month, value: -1, to: visibleMonth) ?? visibleMonth
        case .week:
            visibleMonth = calendar.date(byAdding: .weekOfYear, value: -1, to: visibleMonth) ?? visibleMonth
        case .day:
            visibleMonth = calendar.date(byAdding: .day, value: -1, to: visibleMonth) ?? visibleMonth
        }
    }
    
    private func navigateToNext() {
        switch displayMode {
        case .month:
            visibleMonth = calendar.date(byAdding: .month, value: 1, to: visibleMonth) ?? visibleMonth
        case .week:
            visibleMonth = calendar.date(byAdding: .weekOfYear, value: 1, to: visibleMonth) ?? visibleMonth
        case .day:
            visibleMonth = calendar.date(byAdding: .day, value: 1, to: visibleMonth) ?? visibleMonth
        }
    }
    
    private func navigateToToday() {
        visibleMonth = Date()
        selectedDate = Date()
    }
    
    private func loadTasks() {
        // Calculate date range based on display mode
        var startDate: Date
        var endDate: Date
        
        switch displayMode {
        case .month:
            // Get first day of month
            let components = calendar.dateComponents([.year, .month], from: visibleMonth)
            startDate = calendar.date(from: components) ?? visibleMonth
            
            // Get last day of month
            endDate = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startDate) ?? visibleMonth
            
            // Expand range for visible days from previous/next months
            startDate = calendar.date(byAdding: .day, value: -7, to: startDate) ?? startDate
            endDate = calendar.date(byAdding: .day, value: 7, to: endDate) ?? endDate
            
        case .week:
            // Get first day of week
            let weekday = calendar.component(.weekday, from: visibleMonth)
            startDate = calendar.date(byAdding: .day, value: 1 - weekday, to: visibleMonth) ?? visibleMonth
            endDate = calendar.date(byAdding: .day, value: 7, to: startDate) ?? visibleMonth
            
        case .day:
            startDate = calendar.startOfDay(for: visibleMonth)
            endDate = calendar.date(byAdding: .day, value: 1, to: startDate) ?? visibleMonth
        }
        
        // Fetch tasks in the date range
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Item.dueDate, ascending: true)]
        request.predicate = NSPredicate(format: "dueDate >= %@ AND dueDate < %@", 
                                       startDate as NSDate, 
                                       endDate as NSDate)
        
        do {
            tasks = try viewContext.fetch(request)
        } catch {
            print("Error fetching tasks: \(error)")
            tasks = []
        }
    }
}

// MARK: - Data Models
struct CalendarDay: Identifiable {
    let id = UUID()
    let date: Date
    let isCurrentMonth: Bool
}
