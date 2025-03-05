//
//  CalendarMonthView.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/4/25.
//

import SwiftUI
import CoreData

struct CalendarMonthView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest private var tasks: FetchedResults<Item>
    
    @Binding var currentDate: Date
    @State private var selectedDay: Date? = nil
    
    private let calendar = Calendar.current
    private let daysInWeek = 7
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    init(currentDate: Binding<Date>, context: NSManagedObjectContext) {
        self._currentDate = currentDate
        
        // Create a fetch request for tasks in this month
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Item.dueDate, ascending: true)]
        
        // Filter for tasks in the current month
        let startOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: currentDate.wrappedValue))!
        var components = DateComponents()
        components.month = 1
        components.day = -1
        let endOfMonth = Calendar.current.date(byAdding: components, to: startOfMonth)!
        
        let predicate = NSPredicate(format: "dueDate >= %@ AND dueDate <= %@", startOfMonth as NSDate, endOfMonth as NSDate)
        request.predicate = predicate
        
        self._tasks = FetchRequest(fetchRequest: request)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            CalendarHeaderView(currentDate: $currentDate)
            
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(days, id: \.self) { date in
                    if let date = date {
                        // Day cell with tasks
                        DayCell(
                            date: date,
                            isSelected: selectedDay != nil && calendar.isDate(date, inSameDayAs: selectedDay!),
                            isCurrentMonth: calendar.isDate(date, equalTo: currentDate, toGranularity: .month),
                            isToday: calendar.isDateInToday(date),
                            tasks: tasksForDate(date)
                        )
                        .onTapGesture {
                            selectedDay = date
                        }
                    } else {
                        // Empty cell for days outside the month
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 80)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var days: [Date?] {
        let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate))!
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        
        // 1-based index to 0-based index (Sunday = 1 in Calendar, but we want Sunday = 0)
        let offsetInInitialRow = firstWeekday - 1
        
        let daysInMonth = calendar.range(of: .day, in: .month, for: currentDate)?.count ?? 0
        
        var days: [Date?] = Array(repeating: nil, count: offsetInInitialRow)
        
        // Append actual days of the month
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(date)
            }
        }
        
        // Fill remaining days to complete the grid (6 rows x 7 columns = 42 cells)
        while days.count < 42 {
            days.append(nil)
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

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isCurrentMonth: Bool
    let isToday: Bool
    let tasks: [Item]
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Day number
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 12, weight: isToday ? .bold : .regular))
                .padding(4)
                .background(isToday ? Color.accentColor.opacity(0.3) : Color.clear)
                .cornerRadius(isToday ? 10 : 0)
                .foregroundColor(textColor)
            
            // Tasks for this day (limited to first 3)
            ForEach(Array(tasks.prefix(3)), id: \.id) { task in
                TaskDot(task: task)
            }
            
            // Show count if there are more tasks
            if tasks.count > 3 {
                Text("+\(tasks.count - 3) more")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .frame(height: 80)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(4)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .border(isSelected ? Color.accentColor : Color.clear, width: isSelected ? 1 : 0)
        .opacity(isCurrentMonth ? 1.0 : 0.3)
    }
    
    private var textColor: Color {
        if isToday {
            return .primary
        } else if isCurrentMonth {
            return .primary
        } else {
            return .secondary
        }
    }
}

struct TaskDot: View {
    let task: Item
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(AppColors.getColor(from: task.project?.color))
                .frame(width: 6, height: 6)
            
            Text(task.title ?? "")
                .font(.system(size: 9))
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundColor(task.completed ? .secondary : .primary)
                .strikethrough(task.completed)
        }
    }
}
