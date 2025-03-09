//
//  TagPicker.swift
//  todo-app
//
//  Created on 3/9/25.
//

import SwiftUI
import CoreData

struct TagPicker: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @Binding var selectedTags: Set<Tag>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Tag.name, ascending: true)]
    ) private var allTags: FetchedResults<Tag>
    
    @State private var newTagName = ""
    @State private var newTagColor = "blue"
    @State private var showAddNewTag = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Select Tags")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    showAddNewTag.toggle()
                }) {
                    Label("Add New", systemImage: "plus")
                        .font(.subheadline)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 8)
            
            if showAddNewTag {
                // New tag form
                VStack(spacing: 12) {
                    TextField("Tag Name", text: $newTagName)
                        .textFieldStyle(.roundedBorder)
                    
                    HStack {
                        Text("Color:")
                        
                        ForEach(["red", "orange", "yellow", "green", "blue", "purple", "pink"], id: \.self) { color in
                            Circle()
                                .fill(AppColors.getColor(from: color))
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .stroke(newTagColor == color ? Color.gray : Color.clear, lineWidth: 2)
                                )
                                .onTapGesture {
                                    newTagColor = color
                                }
                        }
                    }
                    
                    HStack {
                        Button("Cancel") {
                            withAnimation {
                                showAddNewTag = false
                                newTagName = ""
                            }
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        Button("Create") {
                            createNewTag()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(newTagName.isEmpty)
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(), value: showAddNewTag)
            }
            
            // Tag list
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(allTags) { tag in
                        HStack {
                            Circle()
                                .fill(AppColors.getColor(from: tag.color))
                                .frame(width: 12, height: 12)
                            
                            Text(tag.name ?? "Unknown Tag")
                            
                            Spacer()
                            
                            Image(systemName: selectedTags.contains(tag) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(selectedTags.contains(tag) ? .blue : .gray)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            toggleTag(tag)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .background(Color.clear)
                        .cornerRadius(8)
                    }
                }
            }
            
            // Footer
            HStack {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 300, height: 400)
    }
    
    private func toggleTag(_ tag: Tag) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
    
    private func createNewTag() {
        guard !newTagName.isEmpty else { return }
        
        let tag = Tag(context: viewContext)
        tag.id = UUID()
        tag.name = newTagName
        tag.color = newTagColor
        
        // Save the context
        do {
            try viewContext.save()
            newTagName = ""
            showAddNewTag = false
        } catch {
            print("Error saving tag: \(error)")
        }
    }
}
