//
//  DoubleClickHandler.swift
//  todo-app
//
//  Created by Bradley Wyatt on 3/5/25.
//

import SwiftUI

struct DoubleClickHandler: ViewModifier {
    @Binding var selectedDate: Date?
    let date: Date
    let doubleClickAction: () -> Void
    
    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .gesture(
                TapGesture(count: 2)
                    .onEnded { _ in
                        // Double click selects and triggers action
                        selectedDate = date
                        doubleClickAction()
                    }
            )
            .onTapGesture {
                // Single click selects the date
                selectedDate = date
            }
    }
}

extension View {
    func handleDoubleClick(selectedDate: Binding<Date?>, date: Date, action: @escaping () -> Void) -> some View {
        self.modifier(DoubleClickHandler(selectedDate: selectedDate, date: date, doubleClickAction: action))
    }
}
