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
import ObjectiveC

// MacOS Calendar View implementation
struct CalendarKitView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var selectedDate: Date?
    @Binding var visibleMonth: Date
    
    // State for visible month and date range
    @State private var displayMode: CalendarDisplayMode = .month
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
        VStack(spacing: 0) {
            // Ensures VStack takes all available space
            Spacer().frame(height: 0)
            // Calendar header with navigation
            HStack {
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
                
                Spacer()
                
                // Navigation buttons
                HStack(spacing: 16) {
                    Button(action: navigateToPrevious) {
                        Image(systemName: "chevron.left")
                    }
                    .buttonStyle(.plain)
                    
                    Button("Today") {
                        navigateToToday()
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: navigateToNext) {
                        Image(systemName: "chevron.right")
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // No bottom spacer, to allow grid to extend to bottom
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            loadTasks()
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

// MARK: - Month Calendar View
struct MonthCalendarView: View {
    @Binding var visibleMonth: Date
    @Binding var selectedDate: Date?
    let tasks: [Item]
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let weekdaySymbols = Calendar.current.shortWeekdaySymbols
    
    var body: some View {
        VStack(spacing: 0) {
            // Weekday header
            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { weekday in
                    Text(weekday)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 0)
            // Add a horizontal divider with zero padding
            Divider()
                .padding(0)
            
            // Calendar grid with gesture support
            GeometryReader { geometry in
                ZStack {
                    LazyVGrid(columns: columns, spacing: 0) {
                        // Day cells with grid lines
                        ForEach(days, id: \.id) { day in
                            CalendarDayCellView(
                                day: day,
                                isSelected: selectedDate != nil && calendar.isDate(day.date, inSameDayAs: selectedDate!),
                                onSelect: {
                                    selectedDate = day.date
                                },
                                tasks: tasksForDate(day.date)
                            )
                            // Dynamically calculate height to fill available space
                            .frame(height: geometry.size.height / 6.001) // Force division to fill entire height
                            .overlay(
                                Rectangle()
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                            )
                        }
                    }
                }
            }
        }
    }
    
    // Calculate all visible days for the month
    private var days: [CalendarDay] {
        // Get the first day of the month
        let components = calendar.dateComponents([.year, .month], from: visibleMonth)
        let firstDayOfMonth = calendar.date(from: components)!
        
        // Get the weekday of the first day (0-based where 0 is Sunday)
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth) - 1
        
        // Get the number of days in the month
        let daysInMonth = calendar.range(of: .day, in: .month, for: visibleMonth)?.count ?? 30
        
        var days: [CalendarDay] = []
        
        // Add days from the previous month to fill the first row
        if firstWeekday > 0 {
            for dayOffset in (1...firstWeekday).reversed() {
                if let date = calendar.date(byAdding: .day, value: -dayOffset, to: firstDayOfMonth) {
                    days.append(CalendarDay(date: date, isCurrentMonth: false))
                }
            }
        }
        
        // Add days from the current month
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(CalendarDay(date: date, isCurrentMonth: true))
            }
        }
        
        // Add days from the next month to complete the grid
        let remainingCells = 42 - days.count // 6 rows of 7 days
        if remainingCells > 0 {
            let lastDayOfMonth = calendar.date(byAdding: .day, value: daysInMonth - 1, to: firstDayOfMonth)!
            for day in 1...remainingCells {
                if let date = calendar.date(byAdding: .day, value: day, to: lastDayOfMonth) {
                    days.append(CalendarDay(date: date, isCurrentMonth: false))
                }
            }
        }
        
        return days
    }
    
    private func tasksForDate(_ date: Date) -> [Item] {
        return tasks.filter { task in
            guard let taskDate = task.dueDate else { return false }
            return calendar.isDate(taskDate, inSameDayAs: date)
        }
    }
}

// MARK: - Week Calendar View
struct WeekCalendarView: View {
    @Binding var visibleMonth: Date
    @Binding var selectedDate: Date?
    let tasks: [Item]
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack {
            // Week calendar implementation
            HStack(spacing: 0) {
                // Time scale column
                VStack(alignment: .trailing, spacing: 0) {
                    ForEach(0..<24, id: \.self) { hour in
                        Text("\(hour):00")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(height: 60)
                            .frame(width: 40, alignment: .trailing)
                            .padding(.trailing, 8)
                    }
                }
                
                // Days columns
                HStack(spacing: 0) {
                    ForEach(weekDays, id: \.id) { day in
                        WeekDayColumn(
                            day: day,
                            isSelected: selectedDate != nil && calendar.isDate(day.date, inSameDayAs: selectedDate!),
                            tasks: tasksForDate(day.date),
                            onSelect: { selectedDate = day.date }
                        )
                    }
                }
            }
        }
    }
    
    private var weekDays: [CalendarDay] {
        let today = visibleMonth
        
        // Find start of the week (Sunday)
        let weekday = calendar.component(.weekday, from: today)
        let startOfWeek = calendar.date(byAdding: .day, value: 1 - weekday, to: today)!
        
        var days: [CalendarDay] = []
        
        // Create 7 days (Sunday through Saturday)
        for day in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: day, to: startOfWeek) {
                days.append(CalendarDay(date: date, isCurrentMonth: calendar.isDate(date, equalTo: today, toGranularity: .month)))
            }
        }
        
        return days
    }
    
    private func tasksForDate(_ date: Date) -> [Item] {
        return tasks.filter { task in
            guard let taskDate = task.dueDate else { return false }
            return calendar.isDate(taskDate, inSameDayAs: date)
        }
    }
}

// MARK: - Day Calendar View
struct DayCalendarView: View {
    @Binding var selectedDate: Date?
    let tasks: [Item]
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 0) {
            // Day view implementation
            ScrollView {
                VStack(spacing: 0) {
                    // Time scale with events
                    ForEach(0..<24, id: \.self) { hour in
                        HStack(spacing: 0) {
                            // Time label
                            Text("\(hour):00")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 50, alignment: .trailing)
                                .padding(.trailing, 8)
                            
                            // Event space
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(height: 60)
                                
                                // Display tasks that fall within this hour
                                ForEach(tasksInHour(hour), id: \.id) { task in
                                    TaskEventView(task: task)
                                        .padding(.leading, 4)
                                }
                            }
                        }
                        .frame(height: 60)
                        
                        // Hour divider
                        Divider()
                    }
                }
                .padding()
            }
        }
    }
    
    private func tasksInHour(_ hour: Int) -> [Item] {
        guard let selectedDate = selectedDate else { return [] }
        
        return tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            
            // Check if it's the same date
            if !calendar.isDate(dueDate, inSameDayAs: selectedDate) {
                return false
            }
            
            // Check if it falls within the hour
            let taskHour = calendar.component(.hour, from: dueDate)
            return taskHour == hour
        }
    }
}

// MARK: - Supporting Views
struct CalendarDayCellView: View {
    let day: CalendarDay
    let isSelected: Bool
    let onSelect: () -> Void
    let tasks: [Item]
    
    private let calendar = Calendar.current
    
    private var isToday: Bool {
        calendar.isDateInToday(day.date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Day number
            Text("\(calendar.component(.day, from: day.date))")
                .font(.subheadline)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)
                .padding(.leading, 4)
            
            // Actual tasks displayed (up to 3)
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(tasks.prefix(3)), id: \.id) { task in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(task.completed ? Color.gray.opacity(0.7) : Color.pink.opacity(0.8))
                            .frame(width: 8, height: 8)
                        
                        Text(task.title ?? "")
                            .font(.system(size: 10))
                            .lineLimit(1)
                            .foregroundColor(task.completed ? .gray : .primary)
                            .strikethrough(task.completed)
                    }
                    .padding(.horizontal, 4)
                }
                
                if tasks.count > 3 {
                    Text("+\(tasks.count - 3) more")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                }
            }
            
            Spacer()
        }
        .background(backgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .padding(1)
        .onTapGesture(perform: onSelect)
    }
    
    private var textColor: Color {
        if !day.isCurrentMonth {
            return Color.gray.opacity(0.5)
        } else if isToday {
            return Color.blue
        } else {
            return Color.primary
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return Color.blue.opacity(0.15)
        } else if isToday {
            return Color.blue.opacity(0.08)
        } else if day.isCurrentMonth {
            return Color.white
        } else {
            // Slightly different background for days outside current month
            return Color.gray.opacity(0.03)
        }
    }
}

struct WeekDayColumn: View {
    let day: CalendarDay
    let isSelected: Bool
    let tasks: [Item]
    let onSelect: () -> Void
    
    private let calendar = Calendar.current
    
    private var isToday: Bool {
        calendar.isDateInToday(day.date)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Day header
            VStack(spacing: 4) {
                Text(dayOfWeekString)
                    .font(.caption)
                    .fontWeight(.medium)
                    
                Text("\(calendar.component(.day, from: day.date))")
                    .font(.headline)
                    .fontWeight(isToday ? .bold : .regular)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .foregroundColor(isToday ? .blue : .primary)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .onTapGesture(perform: onSelect)
            
            // Time grid with events
            ZStack(alignment: .top) {
                // Hour grid lines
                VStack(spacing: 0) {
                    ForEach(0..<24, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 60)
                        Divider()
                    }
                }
                
                // Events
                VStack(spacing: 0) {
                    ForEach(tasks, id: \.id) { task in
                        TaskEventView(task: task)
                            .padding(.horizontal, 4)
                            .offset(y: taskOffset(for: task))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundColor(Color.gray.opacity(0.3)),
            alignment: .trailing
        )
    }
    
    private var dayOfWeekString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: day.date)
    }
    
    private func taskOffset(for task: Item) -> CGFloat {
        guard let taskDate = task.dueDate else { return 0 }
        
        let hour = calendar.component(.hour, from: taskDate)
        let minute = calendar.component(.minute, from: taskDate)
        
        // Calculate offset based on hour and minute (each hour is 60px tall)
        return CGFloat(hour * 60 + minute) * 60 / 60
    }
}

struct TaskEventView: View {
    let task: Item
    
    var body: some View {
        HStack {
            Rectangle()
                .fill(task.completed ? Color.gray : Color.blue)
                .frame(width: 4)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title ?? "")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(task.completed ? .secondary : .primary)
                    .lineLimit(1)
                
                if let dueDate = task.dueDate {
                    Text(timeString(from: dueDate))
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 6)
            
            Spacer()
        }
        .frame(height: 40)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
        )
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Data Models
struct CalendarDay: Identifiable {
    let id = UUID()
    let date: Date
    let isCurrentMonth: Bool
}
