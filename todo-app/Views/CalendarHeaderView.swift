//
//  CalendarHeaderView.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/4/25.
//

import SwiftUI
import AppKit

struct CalendarHeaderView: View {
    @Binding var currentDate: Date
    @State private var showingCalendar = false
    private let calendar = Calendar.current
    
    private let weekdaySymbols = Calendar.current.shortWeekdaySymbols
    
    var body: some View {
        VStack(spacing: 0) {
            // Month and year header
            HStack {
                Button(action: {
                    showingCalendar.toggle()
                }) {
                    HStack {
                        Text(monthYearFormatter.string(from: currentDate))
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .rotationEffect(.degrees(showingCalendar ? 180 : 0))
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                HStack(spacing: 15) {
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
                    
                    Button(action: {
                        withAnimation {
                            currentDate = getNextMonth()
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)
            
            // Days of the week header
            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { weekday in
                    Text(weekday)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 20)
            .padding(.bottom, 10)
            
            // Calendar grid (we'll build this in the actual implementation of the month view)
            Divider()
        }
        .padding(.bottom, 10)
        .background(AppColors.headerBackground)
    }
    
    private func getPreviousMonth() -> Date {
        return calendar.date(byAdding: .month, value: -1, to: currentDate) ?? currentDate
    }
    
    private func getNextMonth() -> Date {
        return calendar.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
    }
    
    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
}
