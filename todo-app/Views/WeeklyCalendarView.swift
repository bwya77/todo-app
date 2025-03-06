//
//  WeeklyCalendarView.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/5/25.
//

import SwiftUI
import CoreData

struct WeeklyCalendarView: View {
    @Binding var selectedDate: Date?
    @Binding var visibleMonth: Date
    @Environment(\.managedObjectContext) private var viewContext
    
    // State for tracking weeks and scroll position
    @State private var weeks: [Week] = []
    @State private var currentWeekIndex: Int = 0
    
    private let calendar = Calendar.current
    private let weekCount = 208 // 4 years (~2 years past, ~2 years future)
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with month and controls
            HStack {
                Text(monthYearString(from: visibleMonth))
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Navigation controls
                HStack(spacing: 16) {
                    Button(action: { scrollToPrevious() }) {
                        Image(systemName: "chevron.left")
                    }
                    .buttonStyle(.plain)
                    
                    Button("Today") {
                        scrollToToday()
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: { scrollToNext() }) {
                        Image(systemName: "chevron.right")
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            
            // Weekday headers
            WeekdayHeaderRow()
            
            // Scrollable weeks
            ScrollView(.vertical, showsIndicators: true) {
                ScrollViewReader { proxy in
                    LazyVStack(spacing: 0) {
                        ForEach(weeks) { week in
                            WeekRow(
                                week: week,
                                selectedDate: $selectedDate
                            )
                            .id(week.id)
                            .frame(height: 100)
                            .onAppear {
                                if let index = weeks.firstIndex(where: { $0.id == week.id }) {
                                    currentWeekIndex = index
                                    updateVisibleMonth()
                                }
                            }
                        }
                    }
                    .onAppear {
                        // Initial scroll to today
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            scrollToToday(proxy: proxy)
                        }
                    }
                }
            }
        }
        .onAppear {
            generateWeeks()
        }
    }
    
    // Generate all weeks
    private func generateWeeks() {
        weeks = []
        let middleIndex = weekCount / 2
        
        // Get today's date
        let today = Date()
        
        for i in 0..<weekCount {
            // Calculate week offset from the middle (today)
            let offset = i - middleIndex
            
            // Calculate the start date of this week
            if let weekDate = calendar.date(byAdding: .weekOfYear, value: offset, to: today) {
                let week = createWeek(startingAround: weekDate, offset: offset)
                weeks.append(week)
            }
        }
    }
    
    // Create a week starting on Sunday
    private func createWeek(startingAround date: Date, offset: Int) -> Week {
        // Find the start of the week (Sunday)
        let weekday = calendar.component(.weekday, from: date)
        let daysToSubtract = weekday - 1 // 1 is Sunday in Gregorian calendar
        
        guard let startOfWeek = calendar.date(byAdding: .day, value: -daysToSubtract, to: date) else {
            return Week(id: UUID(), days: [], weekOfYear: 0, offset: offset)
        }
        
        var days: [Day] = []
        
        // Create 7 days starting from Sunday
        for dayOffset in 0..<7 {
            if let dayDate = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek) {
                days.append(Day(
                    date: dayDate,
                    isToday: calendar.isDateInToday(dayDate)
                ))
            }
        }
        
        let weekOfYear = calendar.component(.weekOfYear, from: startOfWeek)
        return Week(id: UUID(), days: days, weekOfYear: weekOfYear, offset: offset)
    }
    
    // Update the visible month based on the current week
    private func updateVisibleMonth() {
        if currentWeekIndex >= 0 && currentWeekIndex < weeks.count,
           let firstDay = weeks[currentWeekIndex].days.first?.date {
            // Use the first visible day in the week to determine the month
            visibleMonth = firstDay
        }
    }
    
    // Format month and year string
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    // Scroll to today's week
    private func scrollToToday(proxy: ScrollViewProxy? = nil) {
        let middleIndex = weekCount / 2
        currentWeekIndex = middleIndex
        
        if let proxy = proxy, currentWeekIndex < weeks.count {
            withAnimation {
                proxy.scrollTo(weeks[currentWeekIndex].id, anchor: .top)
            }
        }
        
        updateVisibleMonth()
    }
    
    // Scroll to previous week
    private func scrollToPrevious() {
        guard currentWeekIndex > 0 else { return }
        currentWeekIndex -= 1
        updateVisibleMonth()
    }
    
    // Scroll to next week
    private func scrollToNext() {
        guard currentWeekIndex < weeks.count - 1 else { return }
        currentWeekIndex += 1
        updateVisibleMonth()
    }
}

// MARK: - Supporting Views and Models

// Data structure for a week
struct Week: Identifiable {
    let id: UUID
    let days: [Day]
    let weekOfYear: Int
    let offset: Int
}

// Data structure for a day
struct Day: Identifiable {
    let id = UUID()
    let date: Date
    let isToday: Bool
}

// Row of weekday labels
struct WeekdayHeaderRow: View {
    private let weekdays = Calendar.current.shortWeekdaySymbols
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(weekdays, id: \.self) { day in
                Text(day)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
        }
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.3)),
            alignment: .bottom
        )
    }
}

// Row representing a week
struct WeekRow: View {
    let week: Week
    @Binding var selectedDate: Date?
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(week.days) { day in
                WeeklyDayCellView(
                    day: day,
                    isSelected: selectedDate != nil && Calendar.current.isDate(day.date, inSameDayAs: selectedDate!),
                    onSelect: { selectedDate = day.date }
                )
            }
        }
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.2)),
            alignment: .bottom
        )
    }
}

// Cell representing a day
struct WeeklyDayCellView: View {
    let day: Day
    let isSelected: Bool
    let onSelect: () -> Void
    @Environment(\.managedObjectContext) private var viewContext
    @State private var tasks: [Item] = []
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Day number
            Text("\(calendar.component(.day, from: day.date))")
                .font(.subheadline)
                .fontWeight(day.isToday ? .bold : .regular)
                .foregroundColor(day.isToday ? .blue : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)
                .padding(.leading, 4)
            
            // Task indicators
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(tasks.prefix(3)), id: \.id) { task in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(task.completed ? Color.gray.opacity(0.7) : Color.blue.opacity(0.8))
                            .frame(width: 6, height: 6)
                        
                        Text(task.title ?? "")
                            .font(.system(size: 9))
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(cellBackground)
        .onTapGesture(perform: onSelect)
        .onAppear(perform: loadTasks)
    }
    
    private var cellBackground: some View {
        Group {
            if isSelected {
                Color.blue.opacity(0.1)
            } else if day.isToday {
                Color.blue.opacity(0.05)
            } else {
                Color.white
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1.5)
        )
    }
    
    private func loadTasks() {
        let startOfDay = calendar.startOfDay(for: day.date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Item.dueDate, ascending: true)]
        request.predicate = NSPredicate(format: "dueDate >= %@ AND dueDate < %@", 
                                       startOfDay as NSDate, 
                                       endOfDay as NSDate)
        
        do {
            tasks = try viewContext.fetch(request)
        } catch {
            print("Error fetching tasks: \(error)")
            tasks = []
        }
    }
}
