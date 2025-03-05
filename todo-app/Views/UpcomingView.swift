//
//  UpcomingView.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/4/25.
//

import SwiftUI
import CoreData

extension View {
    func border(_ color: Color, width: CGFloat, edges: Edge.Set) -> some View {
        overlay(EdgeBorder(width: width, edges: edges).foregroundColor(color))
    }
}

struct EdgeBorder: Shape {
    var width: CGFloat
    var edges: Edge.Set

    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        if edges.contains(.top) {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        }
        
        if edges.contains(.leading) {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        }
        
        if edges.contains(.bottom) {
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        }
        
        if edges.contains(.trailing) {
            path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        }
        
        return path.strokedPath(StrokeStyle(lineWidth: width))
    }
}

struct UpcomingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var currentDate = Date()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header - fixed height
            Text("Upcoming")
                .font(.system(size: 32, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 0)
                .padding(.bottom, 16)
                .background(Color.white)
            
            // Calendar - fills remaining space
            CalendarView(currentDate: $currentDate, context: viewContext)
        }
        .ignoresSafeArea(edges: .bottom)
        .background(Color.white)
    }
}

struct CalendarView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest private var tasks: FetchedResults<Item>
    
    @Binding var currentDate: Date
    @State private var selectedDay: Date? = Date()
    @State private var currentDay: Date = Date()
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    
    init(currentDate: Binding<Date>, context: NSManagedObjectContext) {
        self._currentDate = currentDate
        
        // Create a fetch request for tasks in this month
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Item.dueDate, ascending: true)]
        
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
            // Calendar header with month/year
            HStack {
                Text("March 2025")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.leading, 16)
                
                Spacer()
                
                HStack(spacing: 10) {
                    Button(action: {
                        withAnimation {
                            currentDate = getPreviousMonth()
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        withAnimation {
                            currentDate = Date()
                        }
                    }) {
                        Text("Today")
                            .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                    .tint(Color.blue)
                    
                    Button(action: {
                        withAnimation {
                            currentDate = getNextMonth()
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button {
                        // Plan action
                    } label: {
                        HStack {
                            Text("Plan: 16")
                            Image(systemName: "doc")
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(.gray)
                }
                .padding(.trailing, 16)
            }
            .padding(.top, 0)
            .padding(.bottom, 8)
            .padding(.horizontal, 16)
            
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(calendar.shortWeekdaySymbols, id: \.self) { weekday in
                    Text(weekday)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 4)
                }
            }
            
            // Fill available space with grid
            GeometryReader { metrics in
                let rows = 6
                let cellHeight = metrics.size.height / CGFloat(rows)
                
                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(Array(zip(days.indices, days)), id: \.0) { index, date in
                        if let date = date {
                            // Day cell with tasks
                            ZStack {
                                Rectangle()
                                    .fill(Color.white)
                                
                                CustomDayCell(
                                    date: date,
                                    isSelected: selectedDay != nil && calendar.isDate(date, inSameDayAs: selectedDay!),
                                    isCurrentMonth: calendar.isDate(date, equalTo: currentDate, toGranularity: .month),
                                    isToday: calendar.isDate(date, inSameDayAs: currentDay),
                                    isPast: date < startOfToday(),
                                    tasks: tasksForDate(date)
                                )
                                .border(Color.gray.opacity(0.2), width: 0.5, edges: .all)
                                .overlay(isToday(date) ? RoundedRectangle(cornerRadius: 0)
                                         .stroke(Color.blue, lineWidth: 1.5) : nil)
                            }
                            .onTapGesture {
                                selectedDay = date
                            }
                            .frame(height: cellHeight)
                        } else {
                            // Empty cell for days outside the month
                            Rectangle()
                                .fill(Color.white)
                                .frame(height: cellHeight)
                                .border(Color.gray.opacity(0.2), width: 0.5, edges: .all)
                        }
                    }
                }
            }
        }
        .background(Color.white)
    }
    
    private func startOfToday() -> Date {
        let today = Date()
        return calendar.startOfDay(for: today)
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
    
    private func isToday(_ date: Date) -> Bool {
        return calendar.isDate(date, inSameDayAs: currentDay)
    }
    
    private func tasksForDate(_ date: Date) -> [Item] {
        return tasks.filter { task in
            guard let taskDate = task.dueDate else { return false }
            return calendar.isDate(taskDate, inSameDayAs: date)
        }
    }
    
    private func getPreviousMonth() -> Date {
        return calendar.date(byAdding: .month, value: -1, to: currentDate) ?? currentDate
    }
    
    private func getNextMonth() -> Date {
        return calendar.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
    }
}

struct CustomDayCell: View {
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
                CustomTaskDot(task: task)
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

struct CustomTaskDot: View {
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

#Preview {
    UpcomingView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
