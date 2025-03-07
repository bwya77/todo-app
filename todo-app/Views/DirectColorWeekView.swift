import SwiftUI
import CoreData
import AppKit

struct DirectColorWeekView: View {
    @Binding var visibleMonth: Date
    @Binding var selectedDate: Date?
    let tasks: [Item]
    
    @EnvironmentObject var timeIndicatorPositioner: TimeIndicatorPositioner
    
    // Hard-coded color without any modifications
    static let FIXED_COLOR = Color(red: 245/255, green: 245/255, blue: 245/255)
    
    var body: some View {
        GeometryReader { geo in
            VStack {
                // Simplified demo view to show gridlines
                Text("Week View with RGB(245,245,245) gridlines")
                    .font(.title)
                
                // Sample grid
                HStack(spacing: 0) {
                    ForEach(0..<7) { _ in
                        VStack {
                            ForEach(0..<5) { _ in
                                Rectangle()
                                    .fill(Color.white)
                                    .frame(height: 50)
                                    .overlay(
                                        Rectangle()
                                            .stroke(DirectColorWeekView.FIXED_COLOR, lineWidth: 1)
                                    )
                            }
                        }
                        .overlay(
                            Rectangle()
                                .frame(width: 1)
                                .foregroundColor(DirectColorWeekView.FIXED_COLOR),
                            alignment: .trailing
                        )
                    }
                }
                .padding()
                
                // Use the real view (it will be hidden behind our demo)
                FixedWeekCalendarView(
                    visibleMonth: $visibleMonth,
                    selectedDate: $selectedDate,
                    tasks: tasks
                )
                .opacity(0.001) // Nearly invisible but still functional
            }
        }
    }
}
