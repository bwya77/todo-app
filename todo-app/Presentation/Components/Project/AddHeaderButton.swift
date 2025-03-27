//
//  AddHeaderButton.swift
//  todo-app
//
//  Created on 3/26/25.
//

import SwiftUI
import CoreData

struct AddHeaderButton: View {
    @Environment(\.managedObjectContext) private var viewContext
    let project: Project
    
    @State private var isShowingInput = false
    @State private var headerTitle = ""
    
    var body: some View {
        VStack {
            if isShowingInput {
                HStack {
                    TextField("Header title", text: $headerTitle, onCommit: {
                        addHeader()
                    })
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color.white)
                    .cornerRadius(4)
                    
                    Button(action: addHeader) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    
                    Button(action: cancelAddHeader) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
                .padding(.horizontal, 4)
                .onAppear {
                    // Focus the text field on appear
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        NSApp.keyWindow?.makeFirstResponder(nil)
                    }
                }
            } else {
                Button(action: {
                    isShowingInput = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                            .font(.system(size: 12))
                        
                        Text("Add Header")
                            .font(.system(size: 12))
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .foregroundColor(.secondary)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        .padding(.vertical, 4)
    }
    
    private func addHeader() {
        let trimmedTitle = headerTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTitle.isEmpty {
            project.addHeader(title: trimmedTitle)
        }
        
        // Reset state
        headerTitle = ""
        isShowingInput = false
    }
    
    private func cancelAddHeader() {
        headerTitle = ""
        isShowingInput = false
    }
}
