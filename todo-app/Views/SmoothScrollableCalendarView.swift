//
//  SmoothScrollableCalendarView.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/5/25.
//

import SwiftUI
import AppKit
import CoreData

struct SmoothScrollableCalendarView: View {
    @Binding var selectedDate: Date?
    @Binding var visibleMonth: Date
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var visibleWeeks: [WeekData] = []
    @State private var scrollPosition: Int = 0
    @State private var loadedWeekRange: ClosedRange<Int> = -104...104 // Two years in each direction
    
    private let calendar = Calendar.current
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 0) {
            // Calendar Header
            HStack {
                Text(monthFormatter.string(from: visibleMonth))
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Navigation buttons
                HStack(spacing: 16) {
                    Button(action: { scrollToOffset(offset: scrollPosition - 4) }) {
                        Image(systemName: "chevron.left")
                    }
                    .buttonStyle(.plain)
                    
                    Button("Today") {
                        scrollToToday()
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: { scrollToOffset(offset: scrollPosition + 4) }) {
                        Image(systemName: "chevron.right")
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            
            // Weekday Headers
            SmoothCalendarWeekdayHeaderView()
                .padding(.top, 5)
            
            // Scrollable calendar
            ScrollViewReader { scrollProxy in
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack(spacing: 0, pinnedViews: []) {
                        ForEach(visibleWeeks) { weekData in
                            SmoothWeekView(
                                weekData: weekData,
                                selectedDate: $selectedDate
                            )
                            .frame(height: 100)
                            .id(weekData.weekOffset)
                            .onAppear {
                                updateVisibleMonth(weekOffset: weekData.weekOffset)
                                
                                // Load more weeks if needed
                                if weekData.weekOffset + 20 >= loadedWeekRange.upperBound {
                                    expandRange(direction: .forward)
                                } else if weekData.weekOffset - 20 <= loadedWeekRange.lowerBound {
                                    expandRange(direction: .backward)
                                }
                            }
                        }
                    }
                }
                .onAppear {
                    loadInitialWeeks()
                    // Scroll to current week
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        scrollToToday()
                    }
                }
                .onChange(of: scrollPosition) { oldValue, newValue in
                    // Set scroll position
                    withAnimation {
                        scrollProxy.scrollTo(newValue, anchor: .top)
                    }
                }
            }
        }
    }
    
    // Scrolls to a specific offset
    private func scrollToOffset(offset: Int) {
        scrollPosition = offset
    }
    
    // Scroll to today
    private func scrollToToday() {
        let todayOffset = 0 // Current week is at offset 0
        scrollPosition = todayOffset
        visibleMonth = Date() // Reset visible month to today
    }
    
    // Update the visible month based on the week that's currently visible
    private func updateVisibleMonth(weekOffset: Int) {
        let today = Date()
        if let newDate = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: today) {
            visibleMonth = newDate
        }
    }
    
    // Direction for expanding loaded weeks
    private enum ExpansionDirection {
        case forward, backward
    }
    
    // Load initial weeks
    private func loadInitialWeeks() {
        var weeks: [WeekData] = []
        for offset in loadedWeekRange {
            weeks.append(createWeekData(offset: offset))
        }
        visibleWeeks = weeks
    }
    
    // Expand the range of loaded weeks
    private func expandRange(direction: ExpansionDirection) {
        var newWeeks: [WeekData] = []
        
        switch direction {
        case .forward:
            let newUpperBound = loadedWeekRange.upperBound + 52 // Add a year
            for offset in (loadedWeekRange.upperBound + 1)...newUpperBound {
                newWeeks.append(createWeekData(offset: offset))
            }
            loadedWeekRange = loadedWeekRange.lowerBound...newUpperBound
            
        case .backward:
            let newLowerBound = loadedWeekRange.lowerBound - 52 // Add a year
            for offset in newLowerBound..<loadedWeekRange.lowerBound {
                newWeeks.append(createWeekData(offset: offset))
            }
            loadedWeekRange = newLowerBound...loadedWeekRange.upperBound
        }
        
        visibleWeeks.append(contentsOf: newWeeks)
        // Sort to ensure proper order
        visibleWeeks.sort { $0.weekOffset < $1.weekOffset }
    }
    
    // Create week data for a specific offset
    private func createWeekData(offset: Int) -> WeekData {
        let today = Date()
        guard let weekStartDate = calendar.date(byAdding: .weekOfYear, value: offset, to: today) else {
            return WeekData(weekOffset: offset, days: [], isCurrentWeek: false)
        }
        
        // Find the start of the week (Sunday)
        let weekday = calendar.component(.weekday, from: weekStartDate)
        let daysToSubtract = weekday - 1
        
        guard let startOfWeek = calendar.date(byAdding: .day, value: -daysToSubtract, to: weekStartDate) else {
            return WeekData(weekOffset: offset, days: [], isCurrentWeek: false)
        }
        
        var days: [DayData] = []
        for dayOffset in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek) {
                let isToday = calendar.isDateInToday(date)
                days.append(DayData(
                    date: date,
                    isToday: isToday
                ))
            }
        }
        
        let isCurrentWeek = offset == 0
        return WeekData(
            weekOffset: offset,
            days: days,
            isCurrentWeek: isCurrentWeek
        )
    }
}

// Represents a week in the calendar
struct WeekData: Identifiable {
    let id = UUID()
    let weekOffset: Int // Offset from current week
    let days: [DayData]
    let isCurrentWeek: Bool
}

// Represents a day in the calendar
struct DayData: Identifiable {
    let id = UUID()
    let date: Date
    let isToday: Bool
}

// Weekday header view for the smooth scrollable calendar
struct SmoothCalendarWeekdayHeaderView: View {
    private let weekdaySymbols = Calendar.current.shortWeekdaySymbols
    
    var body: some View {
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
        .background(Color.white)
        // Add a divider below the weekday header
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.3)),
            alignment: .bottom
        )
    }
}

// Week view component
struct SmoothWeekView: View {
    let weekData: WeekData
    @Binding var selectedDate: Date?
    @Environment(\.managedObjectContext) private var viewContext
    
    private let calendar = Calendar.current
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(weekData.days) { day in
                SmoothDayView(
                    day: day,
                    isSelected: selectedDate != nil && calendar.isDate(day.date, inSameDayAs: selectedDate!),
                    onSelect: { selectedDate = day.date }
                )
            }
        }
        // Add a thin divider below each week
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.2)),
            alignment: .bottom
        )
    }
}

// Day cell component
struct SmoothDayView: View {
    let day: DayData
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
            
            // Tasks for the day (maximum 3)
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(tasks.prefix(3)), id: \.id) { task in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(task.completed ? Color.gray.opacity(0.7) : Color.pink.opacity(0.8))
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
        .onAppear(perform: fetchTasks)
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
    
    private func fetchTasks() {
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
