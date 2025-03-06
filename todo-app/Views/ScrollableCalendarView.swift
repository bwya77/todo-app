//
//  ScrollableCalendarView.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/5/25.
//

import SwiftUI
import CoreData

// Main calendar view
struct ScrollableCalendarView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var scrollOffset: CGFloat = 0
    @State private var monthOffset: Int = 0
    @State private var nextMonthVisible: Bool = false
    @State private var selectedDay: Date? = Date()
    @State private var scrollToMonth: Int? = nil
    @State private var currentMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var currentYear: Int = Calendar.current.component(.year, from: Date())
    @State private var lastScreenHeight: CGFloat = 0 // Store previous screen height
    
    private let calendar = Calendar.current
    
    var body: some View {
        GeometryReader { geometry in
            CalendarContentView(
                scrollOffset: $scrollOffset,
                monthOffset: $monthOffset,
                nextMonthVisible: $nextMonthVisible,
                selectedDay: $selectedDay,
                scrollToMonth: $scrollToMonth,
                currentMonth: $currentMonth,
                currentYear: $currentYear,
                screenHeight: geometry.size.height
            )
            .environment(\.managedObjectContext, viewContext)
            .onChange(of: geometry.size) { oldSize, newSize in
                // Only update if height changed significantly
                if abs(lastScreenHeight - newSize.height) > 1 {
                    lastScreenHeight = newSize.height
                }
            }
            .onAppear {
                lastScreenHeight = geometry.size.height
            }
        }
    }
}

// Main content view for the calendar to reduce complexity
struct CalendarContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var scrollOffset: CGFloat
    @Binding var monthOffset: Int
    @Binding var nextMonthVisible: Bool
    @Binding var selectedDay: Date?
    @Binding var scrollToMonth: Int?
    @Binding var currentMonth: Int
    @Binding var currentYear: Int
    let screenHeight: CGFloat
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 0) {
            // Month header with sticky behavior
            MonthHeaderView(
                monthOffset: monthOffset,
                nextMonthVisible: nextMonthVisible,
                onNavigate: { targetMonth in
                    scrollToMonth = targetMonth
                }
            )
            .background(Color.white)
            .padding(.bottom, 4)
            
            // Weekday headers
            WeekdayHeaderView()
            
            // Calendar grid - fill remaining height
            CalendarGridView(
                viewContext: viewContext,
                scrollOffset: $scrollOffset,
                monthOffset: $monthOffset,
                nextMonthVisible: $nextMonthVisible,
                selectedDay: $selectedDay,
                scrollToMonth: $scrollToMonth,
                currentMonth: $currentMonth,
                currentYear: $currentYear,
                screenHeight: screenHeight
            )
            .frame(maxHeight: .infinity)
        }
        .ignoresSafeArea(edges: .bottom)
        .background(Color.white)
    }
}

// Separate weekday header view
struct WeekdayHeaderView: View {
    private let calendar = Calendar.current
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(calendar.shortWeekdaySymbols, id: \.self) { weekday in
                Text(weekday)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 4)
            }
        }
        .padding(.top, 8)
        .background(Color.white)
        .zIndex(1)
    }
}

// Scrollable calendar grid view
struct CalendarGridView: View {
    let viewContext: NSManagedObjectContext
    @Binding var scrollOffset: CGFloat
    @Binding var monthOffset: Int
    @Binding var nextMonthVisible: Bool
    @Binding var selectedDay: Date?
    @Binding var scrollToMonth: Int?
    @Binding var currentMonth: Int
    @Binding var currentYear: Int
    let screenHeight: CGFloat
    
    // Calculate the height of each month based on screen height
    // Header and weekday row are approximately 120px together
    private var cellHeight: CGFloat {
        // Calculate cell height to ensure 6 rows fit within the available height
        // Leave space for header (approximately 50px) and weekday header (approximately 40px)
        let headerSpace: CGFloat = 90
        let availableHeight = screenHeight - headerSpace
        return availableHeight / 6 // 6 rows per month
    }
    
    var currentDay: Date {
        let today = Date()
        return Calendar.current.startOfDay(for: today)
    }
    
    var body: some View {
        ScrollViewReader { scrollViewProxy in
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 0, pinnedViews: []) {
                    // We'll generate months from past to future months
                    ForEach(-24...36, id: \.self) { offset in
                        MonthGridView(
                            viewContext: viewContext,
                            monthOffset: offset,
                            selectedDay: $selectedDay,
                            currentMonth: $currentMonth,
                            currentYear: $currentYear,
                            cellHeight: cellHeight,
                            onLastWeekVisible: { isVisible in
                                // When the last week of a month becomes visible and it's the next month,
                                // show the next month's header
                                if offset == monthOffset + 1 {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        nextMonthVisible = isVisible
                                    }
                                }
                            }
                        )
                        .id(offset)
                    }
                }
                .background(GeometryReader { geo in
                    Color.clear
                        .preference(key: ScrollOffsetPreferenceKey.self, value: geo.frame(in: .named("scrollView")).minY)
                        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                            // Only update scroll offset if not resizing
                            scrollOffset = value
                            
                            // Determine which month is in view
                            let normalizedOffset = -value
                            
                            // Calculate height of each month grid (6 rows of cells)
                            let monthHeight = cellHeight * 6
                            
                            // Calculate the position in terms of months
                            let currentIndex = Int(normalizedOffset / monthHeight)
                            
                            if currentIndex != monthOffset && currentIndex >= -24 && currentIndex <= 36 {
                                monthOffset = currentIndex
                                
                                // Update current month/year based on offset
                                let calendar = Calendar.current
                                let currentDate = Date()
                                if let newDate = calendar.date(byAdding: .month, value: currentIndex, to: currentDate) {
                                    currentMonth = calendar.component(.month, from: newDate)
                                    currentYear = calendar.component(.year, from: newDate)
                                }
                            }
                        }
                })
            }
            .coordinateSpace(name: "scrollView")
            .id("calendarScroll-\(Int(cellHeight))") // Force rebuild ScrollView when cell height changes
            .onAppear {
                // Scroll to current month on appear
                scrollViewProxy.scrollTo(0, anchor: .top)
            }
            .onChange(of: scrollToMonth) { oldValue, newValue in
                if let target = newValue {
                    withAnimation {
                        scrollViewProxy.scrollTo(target, anchor: .top)
                    }
                    // Reset after scrolling
                    scrollToMonth = nil
                }
            }
            .onChange(of: Int(cellHeight)) { oldHeight, newHeight in
                // Maintain current month view when resizing
                DispatchQueue.main.async {
                    scrollViewProxy.scrollTo(monthOffset, anchor: .top)
                }
            }
        }
    }
}

// Preference key to track scroll position
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// Header container that shows current month with transition
struct MonthHeaderView: View {
    let monthOffset: Int
    let nextMonthVisible: Bool
    let onNavigate: (Int) -> Void
    
    // Control buttons for navigation
    @State private var showControls: Bool = true
    
    private let calendar = Calendar.current
    private let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    var body: some View {
        let currentDate = calendar.date(byAdding: .month, value: monthOffset, to: Date()) ?? Date()
        let nextDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? Date()
        
        ZStack(alignment: .leading) {
            // Current month header
            currentMonthHeader(currentDate)
            
            // Next month header
            if nextMonthVisible {
                nextMonthHeader(nextDate)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: nextMonthVisible)
        .zIndex(2)
    }
    
    private func currentMonthHeader(_ date: Date) -> some View {
        HStack {
            Text(monthYearFormatter.string(from: date))
                .font(.title2)
                .fontWeight(.bold)
                .frame(alignment: .leading)
                
            Spacer()
            
            if showControls {
                headerControls(currentOffset: monthOffset)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.white)
        .opacity(nextMonthVisible ? 0 : 1)
        .offset(y: nextMonthVisible ? -30 : 0)
    }
    
    private func nextMonthHeader(_ date: Date) -> some View {
        HStack {
            Text(monthYearFormatter.string(from: date))
                .font(.title2)
                .fontWeight(.bold)
                .frame(alignment: .leading)
                
            Spacer()
            
            if showControls {
                headerControls(currentOffset: monthOffset + 1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.white)
        .opacity(nextMonthVisible ? 1 : 0)
        .offset(y: nextMonthVisible ? 0 : 30)
    }
    
    private func headerControls(currentOffset: Int) -> some View {
        HStack(spacing: 12) {
            Button(action: {
                // Navigate to previous month
                onNavigate(currentOffset - 1)
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: {
                // Navigate to today/current month
                onNavigate(0)
            }) {
                Text("Today")
                    .font(.subheadline)
            }
            .buttonStyle(.bordered)
            .tint(Color.blue)
            
            Button(action: {
                // Navigate to next month
                onNavigate(currentOffset + 1)
            }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// Monthly grid view component - represents a single month of the calendar
struct MonthGridView: View {
    let viewContext: NSManagedObjectContext
    let monthOffset: Int
    @Binding var selectedDay: Date?
    @Binding var currentMonth: Int
    @Binding var currentYear: Int
    let cellHeight: CGFloat
    let onLastWeekVisible: (Bool) -> Void
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    
    var currentDay: Date {
        return Date()
    }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(Array(zip(days.indices, days)), id: \.0) { index, date in
                if let date = date {
                    // Day cell with tasks
                    DayCellView(
                        viewContext: viewContext,
                        date: date,
                        isSelected: selectedDay != nil && calendar.isDate(date, inSameDayAs: selectedDay!),
                        isCurrentMonth: calendar.isDate(date, equalTo: currentMonthDate, toGranularity: .month),
                        isToday: calendar.isDateInToday(date),
                        isPast: date < calendar.startOfDay(for: Date()),
                        monthOffset: monthOffset,
                        cellHeight: cellHeight,
                        onSelect: { selectedDay = date },
                        isLastSunday: isLastSundayOfMonth(date, index),
                        onVisibilityChange: onLastWeekVisible
                    )
                } else {
                    // Empty cell for days outside the month
                    Rectangle()
                        .fill(Color.white)
                        .frame(height: cellHeight)
                        .overlay(
                            Rectangle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                        )
                }
            }
        }
    }
    
    private var currentMonthDate: Date {
        let date = Date()
        var components = DateComponents()
        components.month = monthOffset
        return calendar.date(byAdding: components, to: date) ?? date
    }
    
    private var days: [Date?] {
        let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonthDate))!
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        
        // 1-based index to 0-based index
        let offsetInInitialRow = firstWeekday - 1
        
        let daysInMonth = calendar.range(of: .day, in: .month, for: currentMonthDate)?.count ?? 0
        
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
        
        // Ensure we only have exactly 42 cells (6 rows x 7 days)
        if days.count > 42 {
            days = Array(days.prefix(42))
        }
        
        return days
    }
    
    private func isLastSundayOfMonth(_ date: Date, _ index: Int) -> Bool {
        // Check if this is the last Sunday of the month
        // First, check if it's a Sunday
        let isSunday = calendar.component(.weekday, from: date) == 1
        if !isSunday {
            return false
        }
        
        // Then check if it's in the last week of the month
        let nextIndex = index + 7
        
        // If next index is out of bounds or the next week date is nil, this is the last Sunday
        if nextIndex >= days.count || days[nextIndex] == nil {
            return true
        }
        
        // If next week date is in a different month, this is the last Sunday
        if let nextWeekDate = days[nextIndex],
           !calendar.isDate(date, equalTo: nextWeekDate, toGranularity: .month) {
            return true
        }
        
        return false
    }
}

// Wrapper to reduce complexity of the day cell
struct DayCellView: View {
    let viewContext: NSManagedObjectContext
    let date: Date
    let isSelected: Bool
    let isCurrentMonth: Bool
    let isToday: Bool
    let isPast: Bool
    let monthOffset: Int
    let cellHeight: CGFloat
    let onSelect: () -> Void
    let isLastSunday: Bool
    let onVisibilityChange: (Bool) -> Void
    
    @State private var tasks: [Item] = []
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.white)
            
            DayContentView(
                date: date,
                isSelected: isSelected,
                isCurrentMonth: isCurrentMonth,
                isToday: isToday,
                isPast: isPast,
                tasks: tasks
            )
            .overlay(
                Rectangle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
            )
            .overlay(isToday ? RoundedRectangle(cornerRadius: 0)
                     .stroke(Color.blue, lineWidth: 1.5) : nil)
        }
        .onTapGesture(perform: onSelect)
        .frame(height: cellHeight)
        .background(
            Group {
                if isLastSunday {
                    GeometryReader { geo in
                        Color.clear
                            .onAppear {
                                onVisibilityChange(true)
                            }
                            .onDisappear {
                                onVisibilityChange(false)
                            }
                    }
                } else {
                    Color.clear
                }
            }
        )
        .onAppear {
            fetchTasks()
        }
    }
    
    private func fetchTasks() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
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

// Day cell component for calendar
struct DayContentView: View {
    let date: Date
    let isSelected: Bool
    let isCurrentMonth: Bool
    let isToday: Bool
    let isPast: Bool
    let tasks: [Item]
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Day number
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 16, weight: isToday ? .bold : .regular))
                .padding(.top, 8)
                .padding(.leading, 10)
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Tasks for this day (limited to first 3)
            ForEach(Array(tasks.prefix(3)), id: \.id) { task in
                TaskDotView(task: task)
            }
            
            // Show count if there are more tasks
            if tasks.count > 3 {
                Text("+\(tasks.count - 3) more")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .padding(.leading, 6)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.white)
        .opacity(cellOpacity)
    }
    
    private var textColor: Color {
        if !isCurrentMonth {
            return Color.gray.opacity(0.6)
        } else if isPast {
            return Color.gray
        } else if isToday {
            return Color.blue
        } else {
            return .black
        }
    }
    
    private var cellOpacity: Double {
        if !isCurrentMonth {
            return 0.5
        } else if isPast {
            return 0.7
        } else {
            return 1.0
        }
    }
}

struct TaskDotView: View {
    let task: Item
    
    var body: some View {
        HStack(spacing: 4) {
            HStack(spacing: 2) {
                Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(.blue.opacity(task.completed ? 0.7 : 1.0))
                    .font(.system(size: 10))
                
                Text(task.title ?? "")
                    .font(.system(size: 11))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundColor(task.completed ? .secondary : .black)
                    .strikethrough(task.completed)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
    }
}
