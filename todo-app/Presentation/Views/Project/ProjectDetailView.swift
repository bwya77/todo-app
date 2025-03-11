//
//  ProjectDetailView.swift
//  todo-app
//
//  Created on 3/10/25.
//

import SwiftUI
import CoreData
import Combine
import AppKit

// Make sure we're using the latest SwiftUI features
#if os(macOS)
import UniformTypeIdentifiers
#endif

class NSEventMonitor {
    static let shared = NSEventMonitor()
    private var lastMousePosition = NSPoint.zero
    
    init() {
        // Start tracking mouse movement globally to have the most accurate position
        NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDown]) { [weak self] event in
            self?.lastMousePosition = NSEvent.mouseLocation
        }
    }
    
    func getCurrentMousePosition() -> NSPoint {
        return NSEvent.mouseLocation
    }
}

// Track mouse location for precise cursor positioning
class CursorLocationTracker {
    static var lastClickLocation: NSPoint?
}

class TextFieldMonitor {
    static let shared = TextFieldMonitor()
    private var monitor: Any? = nil
    private var textFieldId = UUID()
    private weak var currentTextField: NSTextField?
    
    func startMonitoring(textField: NSTextField) {
        stopMonitoring()
        currentTextField = textField
        textFieldId = UUID() // Generate a new ID for this session
        
        // Monitor mouse events to handle subsequent clicks in text field
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown]) { [weak textField] event in
            guard let textField = textField else { return event }
            
            // Check if this is the active text field
            if let fieldEditor = textField.window?.fieldEditor(true, for: textField),
               textField.window?.firstResponder === fieldEditor {
                
                // Check if click is within the text field's frame
                let windowPoint = event.locationInWindow
                let textFieldPoint = textField.convert(windowPoint, from: nil)
                
                if NSPointInRect(textFieldPoint, textField.bounds) {
                    // It's a click in the active text field - handle cursor positioning
                    if let customTextField = textField as? EditableTextFieldWithCursorPlacement {
                        customTextField.clickLocation = textFieldPoint
                        
                        // Delay to position cursor after the event has been processed
                        DispatchQueue.main.async {
                            if let fieldEditor = textField.window?.fieldEditor(true, for: textField) as? NSTextView,
                               let clickPoint = customTextField.clickLocation {
                                // Use the text container system for accurate positioning
                                let containerOffset = fieldEditor.textContainerOrigin
                                let adjustedPoint = NSPoint(
                                    x: clickPoint.x - containerOffset.x,
                                    y: clickPoint.y - containerOffset.y
                                )
                                
                                // Convert click to position in text
                                let glyphIndex = fieldEditor.layoutManager?.glyphIndex(for: adjustedPoint, in: fieldEditor.textContainer!) ?? 0
                                let characterIndex = fieldEditor.layoutManager?.characterIndexForGlyph(at: glyphIndex) ?? 0
                                let safeIndex = min(characterIndex, fieldEditor.string.count)
                                
                                // Set cursor position without selection
                                fieldEditor.selectedRange = NSRange(location: safeIndex, length: 0)
                                customTextField.clickLocation = nil
                            }
                        }
                    }
                }
            }
            return event
        }
    }
    
    func stopMonitoring() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
        currentTextField = nil
    }
    
    deinit {
        stopMonitoring()
    }
}

// Global click monitor to detect clicks outside the text field
class GlobalClickMonitor {
    static let shared = GlobalClickMonitor()
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var keyMonitor: Any?
    
    // Simple flag to track emoji picker state
    var isEmojiPickerActive = false
    var emojiSafetyTimer: Timer? = nil
    var onClickOutside: (() -> Void)?
    
    init() {}
    
    func startMonitoring(view: NSView, action: @escaping () -> Void) {
        stopMonitoring() // Stop any existing monitoring
        onClickOutside = action
        
        // Monitor for emoji picker activation (globe key, fn key, or Control+Command+Space)
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            // Check for Control+Command+Space which opens emoji picker
            if event.type == .keyDown && event.keyCode == 49 && // Space key
               event.modifierFlags.contains([.control, .command]) {
                // Set the flag - will be cleared on click
                self?.isEmojiPickerActive = true
            }
            // Check for globe/fn key (behaves as NSEvent.ModifierFlags.function)
            else if event.type == .flagsChanged && 
                    event.modifierFlags.contains(.function) {
                // Set the flag - will be cleared on click
                self?.isEmojiPickerActive = true
            }
            return event
        }
        
        // Monitor global clicks (outside the app)
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] _ in
            guard let self = self else { return }
            
            // Ignore clicks while emoji picker is active (give it time to complete)
            if self.isEmojiPickerActive {
                return
            }
            
            // Normal click outside - trigger callback
            self.onClickOutside?()
        }
        
        // Monitor local clicks (inside the app)
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown]) { [weak self, weak view] event in
            guard let self = self, let view = view else { return event }
            
            // Get the view that was clicked on
            guard let targetView = event.window?.contentView?.hitTest(event.locationInWindow) else {
                return event
            }
            
            // Check if the clicked window is the emoji picker
            if let window = event.window, window.className.contains("CharacterPicker") {
                // If this is a click in the emoji picker, don't do anything special
                return event
            }
            
            // If emoji picker was active, just clear the flag without triggering click outside
            if self.isEmojiPickerActive {
                self.isEmojiPickerActive = false
                return event
            }
            
            // Check if this is a click on the text field we're monitoring
            let isTargetViewTextField = targetView == view || targetView.isDescendant(of: view) ||
                (targetView.isKind(of: NSTextView.self) && view.window?.firstResponder is EditableTextFieldWithCursorPlacement)
            
            // If not clicking on our text field, trigger the callback
            if !isTargetViewTextField {
                self.onClickOutside?()
            }
            
            return event
        }
    }
    
    func stopMonitoring() {
        if let globalMonitor = globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
        
        if let localMonitor = localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
        
        if let keyMonitor = keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
        
        isEmojiPickerActive = false
        emojiSafetyTimer?.invalidate()
        emojiSafetyTimer = nil
        onClickOutside = nil
    }
    

    

    
    deinit {
        stopMonitoring()
    }
}

class EditableTextFieldWithCursorPlacement: NSTextField {
    var clickLocation: NSPoint?
    
    override func mouseDown(with event: NSEvent) {
        // Capture the mouse position immediately
        clickLocation = convert(event.locationInWindow, from: nil)
        
        // Don't call super to avoid default selection behavior
        // Instead, manually become first responder
        if window?.firstResponder != self {
            window?.makeFirstResponder(self)
        } else {
            // If already first responder, position cursor manually
            positionCursorAtClickPoint()
        }
    }
    
    // Handle key events to support emoji input
    override func keyDown(with event: NSEvent) {
        // Check if this might be the emoji picker shortcut
        if event.keyCode == 49 && event.modifierFlags.contains([.control, .command]) {
            // This is Command+Control+Space for emoji picker
            GlobalClickMonitor.shared.isEmojiPickerActive = true
        }
        
        super.keyDown(with: event)
    }
    
    // Override to directly edit instead of selecting
    override func performClick(_ sender: Any?) {
        // Don't perform the standard click which selects all text
        // Instead we'll manually handle the editing below
        window?.makeFirstResponder(self)
    }
    
    override func becomeFirstResponder() -> Bool {
        // Become first responder first to get the field editor ready
        let result = super.becomeFirstResponder()
        
        // Immediately position cursor - using next run loop often causes problems
        self.positionCursorAtClickPoint()
        
        return result
    }
    
    // Position cursor based on clicked point
    func positionCursorAtClickPoint() {
        guard let fieldEditor = window?.fieldEditor(true, for: self) as? NSTextView,
              let clickPoint = self.clickLocation else { return }
        
        // Use the text container system for accurate positioning
        let containerOffset = fieldEditor.textContainerOrigin
        let adjustedPoint = NSPoint(
            x: clickPoint.x - containerOffset.x,
            y: clickPoint.y - containerOffset.y
        )
        
        // Find position in text at click point
        if let glyphIndex = fieldEditor.layoutManager?.glyphIndex(for: adjustedPoint, in: fieldEditor.textContainer!) {
            let characterIndex = fieldEditor.layoutManager?.characterIndexForGlyph(at: glyphIndex) ?? 0
            let safeIndex = min(characterIndex, fieldEditor.string.count)
            
            // Position cursor at clicked position without selection
            fieldEditor.selectedRange = NSRange(location: safeIndex, length: 0)
        }
    }
}

// Custom TextField to prevent text selection on focus
struct NoSelectionTextField: NSViewRepresentable {
    @Binding var text: String
    var onCommit: () -> Void
    var onStartEditing: (NSTextField) -> Void = { _ in }
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: NoSelectionTextField
        var isEmojiPickerActive = false
        private var lastTextChangeTime: Date? = nil
        
        init(_ parent: NoSelectionTextField) {
            self.parent = parent
        }
        
        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                parent.text = textField.stringValue
                lastTextChangeTime = Date()
                
                // If we detect a text change while emoji picker is active, this may be an emoji insertion
                // We do nothing special here, just update the text and let natural text field behavior occur
            }
        }
        
        // Explicitly handle text editing end event
        func controlTextDidEndEditing(_ obj: Notification) {
            // Check for emoji picker state to handle emoji insertion
            if GlobalClickMonitor.shared.isEmojiPickerActive {
                // Don't commit changes if emoji picker was active
                return
            }
            
            // Regular end editing - commit the changes
            parent.onCommit()
        }
        
        // Handle keyboard selection change notification (triggered by emoji picker)
        @objc func handleTextInputChange(_ notification: Notification) {
            // Set the emoji picker as active
            GlobalClickMonitor.shared.isEmojiPickerActive = true
            lastTextChangeTime = Date()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> NSTextField {
        let textField = EditableTextFieldWithCursorPlacement()
        textField.stringValue = text
        textField.font = NSFont.boldSystemFont(ofSize: 24)
        textField.isBezeled = false
        textField.isEditable = true
        textField.isSelectable = true
        textField.drawsBackground = false
        textField.focusRingType = .none
        textField.delegate = context.coordinator
        
        // Register for notifications about NSTextInput changes which happen with emoji picker
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.handleTextInputChange(_:)),
            name: NSTextInputContext.keyboardSelectionDidChangeNotification,
            object: nil
        )
        
        // Set up key event handling for escape key
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 /* ESC */ && textField.window?.firstResponder == textField {
                context.coordinator.parent.onCommit()
                return nil // Consume the event
            }
            return event
        }
        
        // Make the field first responder immediately
        DispatchQueue.main.async {
            if let window = NSApp.keyWindow {
                // Pass the last click location if available
                if let lastClick = CursorLocationTracker.lastClickLocation {
                    // Convert the window location to the text field's coordinate space
                    textField.clickLocation = textField.convert(lastClick, from: nil)
                    
                    // Focus the text field
                    window.makeFirstResponder(textField)
                } else {
                    window.makeFirstResponder(textField)
                }
                
                // Notify parent view that editing has started
                context.coordinator.parent.onStartEditing(textField)
                
                // Reset for next time
                CursorLocationTracker.lastClickLocation = nil
            }
        }
        
        return textField
    }
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }
    
    static func dismantleNSView(_ nsView: NSTextField, coordinator: Coordinator) {
        // Make sure we don't leave any event monitors active
        if let window = nsView.window, window.firstResponder == nsView {
            window.makeFirstResponder(nil)
        }
        
        // Remove notification observer
        NotificationCenter.default.removeObserver(coordinator)
    }
}

struct ProjectDetailView: View {
    // Keep reference to monitors
    private let clickMonitor = GlobalClickMonitor.shared
    private let textFieldMonitor = TextFieldMonitor.shared
    private let mouseMonitor = NSEventMonitor.shared
    
    // Timer to handle potential focus changes due to emoji picker
    @State private var focusRetentionTimer: Timer? = nil
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var project: Project
    @StateObject private var taskViewModel: TaskViewModel
    
    // State for editing project title
    @State private var isEditingTitle: Bool = false
    @State private var editedTitle: String = ""
    
    // State for task list
    @FetchRequest private var tasks: FetchedResults<Item>
    
    // Project color for UI elements
    private var projectColor: Color {
        AppColors.getColor(from: project.color)
    }
    
    init(project: Project, context: NSManagedObjectContext) {
        self.project = project
        self._taskViewModel = StateObject(wrappedValue: TaskViewModel(context: context))
        
        // Create a fetch request for tasks in this project
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        request.predicate = NSPredicate(format: "project == %@", project)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Item.completed, ascending: true),
            NSSortDescriptor(keyPath: \Item.dueDate, ascending: true),
            NSSortDescriptor(keyPath: \Item.priority, ascending: false),
            NSSortDescriptor(keyPath: \Item.title, ascending: true)
        ]
        
        self._tasks = FetchRequest(fetchRequest: request)
        self._editedTitle = State(initialValue: project.name ?? "Untitled Project")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Project header with editable title
            VStack(alignment: .leading, spacing: 8) {
                // Title section with simpler editing approach
                ZStack(alignment: .leading) {
                    if isEditingTitle {
                        NoSelectionTextField(text: $editedTitle, onCommit: saveProjectTitle, onStartEditing: { textField in
                            // Start monitoring for clicks outside the text field
                            self.clickMonitor.startMonitoring(view: textField) {
                                if self.isEditingTitle {
                                    self.saveProjectTitle()
                                }
                            }
                            
                            // Also start monitoring for clicks inside the field to correctly position cursor
                            self.textFieldMonitor.startMonitoring(textField: textField)
                        })
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                    } else {
                        HStack(spacing: 10) {
                            // Project completion indicator
                            ProjectCompletionIndicator(
                                project: project,
                                size: 20,
                                viewContext: viewContext
                            )
                            
                            Text(project.name ?? "Untitled Project")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(Color.primary) // Make sure text color is normal
                        }
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                        .help("Click to edit project title")
                        .onHover { hovering in
                            if hovering {
                                NSCursor.iBeam.set()
                            } else {
                                NSCursor.arrow.set()
                            }
                        }
                        .background(
                            // Add a subtle highlight on hover to indicate it's clickable
                            Color.gray.opacity(0.0001) // Nearly invisible but catches clicks
                        )
                        .onTapGesture { location in
                            // Get and store the current mouse position directly
                            if let windowRef = NSApp.keyWindow {
                                let screenPoint = NSEventMonitor.shared.getCurrentMousePosition()
                                let windowPoint = windowRef.convertPoint(fromScreen: screenPoint)
                                CursorLocationTracker.lastClickLocation = windowPoint
                            }
                            startEditingTitle()
                        }
                    }
                }
                
                // Space for padding
                Spacer()
                    .frame(height: 4)
            }
            .padding(.horizontal, 16)
            .padding(.top, 28)
            .padding(.bottom, 16)
            .background(Color.white)
            
            // Divider
            Divider()
                .padding(.horizontal, 16)
            
            // Tasks list
            if tasks.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 48))
                        .foregroundColor(Color.gray.opacity(0.5))
                    
                    Text("No tasks in this project")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Add a task to get started")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        showAddTaskPopup()
                    }) {
                        Text("Add Task")
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(AppColors.getColor(from: project.color).opacity(0.2))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(tasks) { task in
                            TaskRow(task: task, onToggleComplete: toggleTaskCompletion)
                                .contextMenu {
                                    Button(action: {
                                        if let index = tasks.firstIndex(of: task) {
                                            deleteTasks(at: IndexSet(integer: index))
                                        }
                                    }) {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            
                            // We're explicitly NOT adding any dividers
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .background(Color.white)
            }
            
            // Bottom add task button removed
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .onAppear {
            // Ensure we have the latest data
            editedTitle = project.name ?? "Untitled Project"
        }
        // Add a global submit handler to handle tapping outside the field
        .onSubmit(of: .text) {
            if isEditingTitle {
                saveProjectTitle()
            }
        }
        .overlay {
            // Empty overlay - removed
        }
    }
    
    // MARK: - Private Methods
    
    // Enhance our model to also pass the click point
    private func startEditingTitle(clickPoint: NSPoint? = nil) {
        // Set up the editing state
        editedTitle = project.name ?? "Untitled Project"
        
        // Set editing to true
        isEditingTitle = true
    }
    
    private func saveProjectTitle() {
        guard isEditingTitle else { return }
        
        // Don't save or stop editing if emoji picker might be active
        if clickMonitor.isEmojiPickerActive {
            // We don't want to save while emoji picker is active
            return
        }
        
        finalizeSaveProjectTitle()
    }
    
    private func finalizeSaveProjectTitle() {
        guard isEditingTitle else { return }
        
        // Mark as not editing
        isEditingTitle = false
        
        // Stop all monitoring
        clickMonitor.stopMonitoring()
        textFieldMonitor.stopMonitoring()
        
        // Trim whitespace and ensure we have a valid title
        let trimmedTitle = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTitle.isEmpty, trimmedTitle != project.name {
            // Update the project name
            taskViewModel.updateProject(project, name: trimmedTitle)
        }
    }
    
    private func toggleTaskCompletion(_ task: Item) {
        taskViewModel.toggleTaskCompletion(task)
    }
    
    private func deleteTasks(at offsets: IndexSet) {
        withAnimation {
            offsets.map { tasks[$0] }.forEach { task in
                taskViewModel.deleteTask(task)
            }
        }
    }
    
    private func showAddTaskPopup() {
        // Implement showing the add task popup with the current project pre-selected
        // Post a notification that ContentView will listen for to show the add task popup
        // with the current project pre-selected
        NotificationCenter.default.post(
            name: NSNotification.Name("ShowAddTaskPopup"),
            object: nil,
            userInfo: ["project": project]
        )
    }
}

// Extension for TextField ESC key handling
extension View {
    func onExitCommand(perform action: @escaping () -> Void) -> some View {
        self.background(KeyPressHandler(key: .escape, action: action))
    }
}

// Helper for binding escape key to actions
struct KeyPressHandler: NSViewRepresentable {
    let key: KeyEquivalent
    let action: () -> Void
    
    class Coordinator: NSObject {
        var action: () -> Void
        
        init(action: @escaping () -> Void) {
            self.action = action
        }
        
        @objc func handleKeyDown(_ event: NSEvent) -> Bool {
            guard event.type == .keyDown else { return false }
            
            if event.specialKey == .escape {
                action()
                return true
            }
            return false
        }
    }
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        let coordinator = context.coordinator
        
        // Create a local monitor for keypresses
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if coordinator.handleKeyDown(event) {
                return nil // Event handled, don't propagate
            }
            return event // Not our key, pass it on
        }
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(action: action)
    }
}

// KeyEquivalent enum for convenient key representation
enum KeyEquivalent {
    case escape
    // Add more keys as needed
}

// NSEvent extension to make handling keyboard events easier
extension NSEvent {
    var specialKey: KeyEquivalent? {
        guard self.type == .keyDown else { return nil }
        
        switch self.keyCode {
        case 53: return .escape
        default: return nil
        }
    }
}
