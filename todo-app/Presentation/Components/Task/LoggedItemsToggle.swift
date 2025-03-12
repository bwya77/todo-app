//
//  LoggedItemsToggle.swift
//  todo-app
//
//  Created on 3/12/25.
//

import SwiftUI

struct LoggedItemsToggle: View {
    @Binding var isExpanded: Bool
    let itemCount: Int
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        }) {
            HStack {
                Text(isExpanded ? "Hide logged items" : "Show logged items")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.secondary)
                
                if itemCount > 0 {
                    Text("(\(itemCount))")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.secondary)
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack {
        LoggedItemsToggle(isExpanded: .constant(false), itemCount: 5)
        Divider()
        LoggedItemsToggle(isExpanded: .constant(true), itemCount: 3)
    }
    .padding()
    .frame(width: 300)
}
