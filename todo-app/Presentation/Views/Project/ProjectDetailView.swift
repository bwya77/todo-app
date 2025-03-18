// Struct to allow animations only for logged items section
struct AnimatedLoggedSection<Content: View>: View {
    let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        content()
            // Only animate when items move between sections
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .move(edge: .bottom)),
                removal: .opacity.combined(with: .move(edge: .top))
            ))
    }
}

// Struct to disable animations for a section of content
struct AnimationDisabledSection<Content: View>: View {
    let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        content()
            .transaction { transaction in
                // Disable all animations within this section
                transaction.animation = nil
            }
    }
}

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
        
        // Position cursor with a very slight delay to ensure field editor is ready
        // This helps with the new HStack layout where timing can be slightly different
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [weak self] in
            self?.positionCursorAtClickPoint()
        }
        
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
        } else {
            // Fallback if we can't determine exact position - place cursor at end
            fieldEditor.selectedRange = NSRange(location: fieldEditor.string.count, length: 0)
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
        textField.lineBreakMode = .byTruncatingTail
        textField.maximumNumberOfLines = 1
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
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
    // Separate fetch requests for active and completed tasks
    @FetchRequest private var activeTasks: FetchedResults<Item>
    @FetchRequest private var loggedTasks: FetchedResults<Item>
    
    // State for the completed tasks section
    @State private var showLoggedItems: Bool = false
    @State private var taskToLog: Item? = nil
    @State private var taskCompletionTimer: Timer? = nil
    @State private var taskUpdateCounter: Int = 0
    
    // State for tracking tasks that are visually completed but not yet moved to the logged section
    @State private var pendingLoggedTaskIds: [UUID] = []
    
    // Project color for UI elements
    private var projectColor: Color {
        AppColors.getColor(from: project.color)
    }
    
    // MARK: - Lifecycle Methods

    init(project: Project, context: NSManagedObjectContext) {
        self.project = project
        self._taskViewModel = StateObject(wrappedValue: TaskViewModel(context: context))
        
        // Fetch all active and recently completed but not logged tasks
        let activeRequest: NSFetchRequest<Item> = Item.fetchRequest()
        activeRequest.predicate = NSPredicate(format: "project == %@ AND (completed == NO OR (completed == YES AND logged == NO))", project)
        activeRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \Item.dueDate, ascending: true),
            NSSortDescriptor(keyPath: \Item.priority, ascending: false),
            NSSortDescriptor(keyPath: \Item.title, ascending: true)
        ]
        
        // Create a fetch request for logged tasks in this project
        let loggedRequest: NSFetchRequest<Item> = Item.fetchRequest()
        loggedRequest.predicate = NSPredicate(format: "project == %@ AND completed == YES AND logged == YES", project)
        loggedRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \Item.dueDate, ascending: false),
            NSSortDescriptor(keyPath: \Item.title, ascending: true)
        ]
        
        self._activeTasks = FetchRequest(fetchRequest: activeRequest)
        self._loggedTasks = FetchRequest(fetchRequest: loggedRequest)
        self._editedTitle = State(initialValue: project.name ?? "Untitled Project")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Project header with editable title
            VStack(alignment: .leading, spacing: 8) {
                // Title section with simpler editing approach
                ZStack(alignment: .leading) {
                    if isEditingTitle {
                        HStack(spacing: 10) {
                            // Keep the project status indicator visible during editing
                            ProjectCompletionIndicator(
                                project: project,
                                size: 20,
                                viewContext: viewContext
                            )
                            // Add a unique ID for this instance to force recreation when project changes
                            .id("project-indicator-edit-mode-\(project.id?.uuidString ?? UUID().uuidString)")
                            
                            // Text field for editing
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
                        }
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
                            // Add a unique ID for this instance to force recreation when project changes
                            .id("project-indicator-\(project.id?.uuidString ?? UUID().uuidString)")
                            
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
                            // Get and store the current mouse position directly for cursor positioning
                            if let windowRef = NSApp.keyWindow {
                                let screenPoint = NSEventMonitor.shared.getCurrentMousePosition()
                                let windowPoint = windowRef.convertPoint(fromScreen: screenPoint)
                                
                                // Store the click location for cursor positioning
                                CursorLocationTracker.lastClickLocation = windowPoint
                                
                                // Detect if the indicator was clicked or the text was clicked
                                // We only want to start editing if the text was clicked
                                // Since we can't easily detect exactly where in the HStack we clicked,
                                // we'll use a 30-point threshold from the left (indicator width + padding)
                                // This assumes the click coordinates are relative to the containing view
                                // If text was clicked, proceed with editing
                                startEditingTitle()
                            }
                        }
                    }
                }
                
                // Space for padding
                Spacer()
                    .frame(height: 4)
            }
            .padding(.horizontal, 16)
            .padding(.top, 28)
            .padding(.bottom, 8)
            .background(Color.white)
            
        // Project Notes - Directly using the bound project.notes property with unique ID
        ProjectNotesEditor(
            text: Binding(
                get: { self.project.notes ?? "" },
                set: { newValue in
                    self.project.notes = newValue
                    do {
                        try self.viewContext.save()
                    } catch {
                        print("Error saving project notes: \(error)")
                    }
                }
            ),
            placeholder: "Notes", 
            font: .system(size: 14, weight: .regular)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        // Force complete recreation of text editor when project changes
        .id("project-notes-editor-\(self.project.id?.uuidString ?? UUID().uuidString)")
            
            // Divider after title
            CustomDivider()
                .padding(.horizontal, 16)
                .padding(.bottom, 0)
            
            // Tasks list
            if activeTasks.isEmpty && loggedTasks.isEmpty {
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
                List {
                    // Disable animations completely for this section to prevent any movement
                    // when task completion state changes
                    AnimationDisabledSection {
                        // Active tasks (incomplete + newly completed but not logged yet)
                        ForEach(activeTasks) { task in
                            // Track if this task is in pending state
                            let isPending = task.id != nil && pendingLoggedTaskIds.contains(task.id!)
                            
                            TaskRow(task: task, onToggleComplete: toggleTaskCompletion)
                                .id("task-\(task.id?.uuidString ?? UUID().uuidString)-\(taskUpdateCounter)")
                                .opacity(isPending ? 0.8 : 1.0)
                                .background(isPending ? Color.secondary.opacity(0.1) : Color.clear)
                                .cornerRadius(6)
                                .contextMenu {
                                    Button(action: {
                                        deleteTask(task)
                                    }) {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                // No movement transitions on completion - task stays in place
                                .transition(.identity)
                        }
                        .onMove { source, destination in
                            moveActiveTasks(from: source, to: destination)
                        }
                    }
                        
                        // Show the logged items toggle if there are any completed tasks
                        if !loggedTasks.isEmpty {
                            Section(header: LoggedItemsToggle(isExpanded: $showLoggedItems, itemCount: loggedTasks.count)) {
                                if showLoggedItems {
                                    AnimatedLoggedSection {
                                        // Logged tasks section
                                        ForEach(loggedTasks) { task in
                                            TaskRow(task: task, onToggleComplete: toggleTaskCompletion)
                                                .id("logged-task-\(task.id?.uuidString ?? UUID().uuidString)-\(taskUpdateCounter)")
                                                .opacity(0.7) // Make logged items appear slightly faded
                                                .contextMenu {
                                                    Button(action: {
                                                        deleteTask(task)
                                                    }) {
                                                        Label("Delete", systemImage: "trash")
                                                    }
                                                }
                                        }
                                        .onMove { source, destination in
                                            moveLoggedTasks(from: source, to: destination)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(SidebarListStyle())
                    .background(Color.white)
                    // Handle animations carefully - only animate what we explicitly want to animate
                    .animation(nil, value: taskUpdateCounter) // Explicitly disable task update animations
                    .animation(nil, value: pendingLoggedTaskIds) // Disable pending task animations
                    .animation(.easeInOut(duration: 0.3), value: showLoggedItems) // Only animate logged section toggle
            }
            
            // Bottom add task button removed
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        // Force the view to have a unique identity for each project
        .id("project-detail-view-\(project.id?.uuidString ?? UUID().uuidString)")
        .onAppear {
            // Ensure we have the latest data
            editedTitle = project.name ?? "Untitled Project"
            
            // Reset pending tasks state
            pendingLoggedTaskIds.removeAll()
            
            // Verify logged items are collapsed by default
            showLoggedItems = false
            
            // Check for any tasks that were completed but not logged (could happen if app was closed during timer)
            DispatchQueue.main.async {
                for task in activeTasks where task.completed && !task.logged {
                    if let completionDate = task.completionDate {
                        let timeSinceCompletion = Date().timeIntervalSince(completionDate)
                        
                        // If completed more than 2 seconds ago, log immediately without animation
                        if timeSinceCompletion > 2.0 {
                            withAnimation(nil) {
                                taskViewModel.markTaskAsLogged(task)
                                taskUpdateCounter += 1
                            }
                        } 
                        // Otherwise, add to pending list and schedule to be logged at the right time
                        else if let taskId = task.id {
                            pendingLoggedTaskIds.append(taskId)
                            
                            // Schedule remaining time
                            let remainingTime = max(0.1, 2.0 - timeSinceCompletion)
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + remainingTime) {
                                // Get fresh reference to task
                                let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
                                fetchRequest.predicate = NSPredicate(format: "id == %@", taskId as CVarArg)
                                
                                do {
                                    if let updatedTask = try self.viewContext.fetch(fetchRequest).first,
                                       updatedTask.completed && !updatedTask.logged {
                                        
                                        // Create a transaction with a spring animation for sliding to the logged section
                                        let transaction = Transaction(animation: .spring(response: 0.5, dampingFraction: 0.7))
                                        
                                        // Execute the state changes with the transaction
                                        withTransaction(transaction) {
                                            self.taskViewModel.markTaskAsLogged(updatedTask)
                                            self.taskUpdateCounter += 1
                                        }
                                        
                                        // Remove from pending list outside the transaction
                                        if let index = self.pendingLoggedTaskIds.firstIndex(of: taskId) {
                                            self.pendingLoggedTaskIds.remove(at: index)
                                        }
                                    } else {
                                        // Task is gone or no longer needs to be logged
                                        if let index = self.pendingLoggedTaskIds.firstIndex(of: taskId) {
                                            self.pendingLoggedTaskIds.remove(at: index)
                                        }
                                    }
                                } catch {
                                    print("Error handling pending task on appear: \(error)")
                                    // Clean up pending list
                                    if let index = self.pendingLoggedTaskIds.firstIndex(of: taskId) {
                                        self.pendingLoggedTaskIds.remove(at: index)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .onDisappear {
            // Log any pending tasks when view disappears
            for taskId in pendingLoggedTaskIds {
                let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", taskId as CVarArg)
                
                do {
                    if let task = try viewContext.fetch(fetchRequest).first,
                       task.completed && !task.logged {
                        taskViewModel.markTaskAsLogged(task)
                    }
                } catch {
                    print("Error logging pending task on disappear: \(error)")
                }
            }
            
            // Clear pending list
            pendingLoggedTaskIds.removeAll()
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
        let wasCompleted = task.completed
        
        // CASE 1: Task was logged and is being uncompleted - move it back to active immediately
        if wasCompleted && task.logged {
            withAnimation(.easeInOut(duration: 0.3)) {
                taskViewModel.toggleTaskCompletion(task)
                taskUpdateCounter += 1
            }
            return
        }
        
        // CASE 2: Task is being completed
        if !wasCompleted {
            // Temporarily disable animations to prevent any movement
            withAnimation(nil) {
                // Toggle completion state without animation
                taskViewModel.toggleTaskCompletion(task)
                taskUpdateCounter += 1
            }
            // Add task to pending list so it stays in place
            if let taskId = task.id {
                pendingLoggedTaskIds.append(taskId)
                
                // Schedule a timer to move this task to logged section after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    // Verify task still exists and is still completed
                    let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "id == %@", taskId as CVarArg)
                    
                    do {
                        if let updatedTask = try self.viewContext.fetch(fetchRequest).first,
                           updatedTask.completed && !updatedTask.logged {
                            
                            // Check if this is the first logged task
                            let wasEmpty = self.loggedTasks.isEmpty
                            
                            // Create a transaction with spring animation for sliding to logged section
                            let transaction = Transaction(animation: .spring(response: 0.5, dampingFraction: 0.7))
                            
                            // Only the final movement to logged section should be animated
                            withTransaction(transaction) {
                            self.taskViewModel.markTaskAsLogged(updatedTask)
                            self.taskUpdateCounter += 1
                            }
                            
                            // Remove from pending list
                            if let index = self.pendingLoggedTaskIds.firstIndex(of: taskId) {
                                self.pendingLoggedTaskIds.remove(at: index)
                            }
                            
                            // If this was the first logged task, ensure section stays collapsed
                            if wasEmpty {
                                self.showLoggedItems = false
                            }
                        } else {
                            // Task either no longer exists or is no longer completed
                            // Remove from pending list
                            if let index = self.pendingLoggedTaskIds.firstIndex(of: taskId) {
                                self.pendingLoggedTaskIds.remove(at: index)
                            }
                        }
                    } catch {
                        print("Error handling task logging: \(error)")
                        // Clean up pending list
                        if let index = self.pendingLoggedTaskIds.firstIndex(of: taskId) {
                            self.pendingLoggedTaskIds.remove(at: index)
                        }
                    }
                }
            }
        }
        // CASE 3: Task was completed but not logged, and is being uncompleted
        else if !task.logged {
            // Simply toggle it back
            taskViewModel.toggleTaskCompletion(task)
            
            // Remove from pending list if it was there
            if let taskId = task.id, let index = pendingLoggedTaskIds.firstIndex(of: taskId) {
                pendingLoggedTaskIds.remove(at: index)
            }
        }
        
        // Update the counter to trigger view updates
        taskUpdateCounter += 1
    }
    
    private func deleteTask(_ task: Item) {
        withAnimation {
            taskViewModel.deleteTask(task)
            
            // Remove from pending list if it was there
            if let taskId = task.id, let index = pendingLoggedTaskIds.firstIndex(of: taskId) {
                pendingLoggedTaskIds.remove(at: index)
            }
            
            taskUpdateCounter += 1
        }
    }
    
    private func moveActiveTasks(from source: IndexSet, to destination: Int) {
        // Store the task ordering in UserDefaults
        var orderDict = UserDefaults.standard.dictionary(forKey: "ActiveTaskOrdering") as? [String: Int] ?? [:]
        
        // Create a mutable copy of the tasks
        var tasks = Array(activeTasks)
        
        // Perform the move operation
        tasks.move(fromOffsets: source, toOffset: destination)
        
        // Update the ordering for each task
        for (index, task) in tasks.enumerated() {
            if let taskId = task.id?.uuidString {
                orderDict[taskId] = index
            }
        }
        
        // Save the ordering
        UserDefaults.standard.set(orderDict, forKey: "ActiveTaskOrdering")
        
        // Save the context
        do {
            try viewContext.save()
            taskUpdateCounter += 1
        } catch {
            print("Failed to save context after reordering: \(error)")
        }
    }
    
    private func moveLoggedTasks(from source: IndexSet, to destination: Int) {
        // Store the task ordering in UserDefaults
        var orderDict = UserDefaults.standard.dictionary(forKey: "LoggedTaskOrdering") as? [String: Int] ?? [:]
        
        // Create a mutable copy of the tasks
        var tasks = Array(loggedTasks)
        
        // Perform the move operation
        tasks.move(fromOffsets: source, toOffset: destination)
        
        // Update the ordering for each task
        for (index, task) in tasks.enumerated() {
            if let taskId = task.id?.uuidString {
                orderDict[taskId] = index
            }
        }
        
        // Save the ordering
        UserDefaults.standard.set(orderDict, forKey: "LoggedTaskOrdering")
        
        // Save the context
        do {
            try viewContext.save()
            taskUpdateCounter += 1
        } catch {
            print("Failed to save context after reordering: \(error)")
        }
    }
    
    private func deleteTasks(at offsets: IndexSet, isActive: Bool) {
        withAnimation {
            if isActive {
                offsets.map { activeTasks[$0] }.forEach { task in
                    taskViewModel.deleteTask(task)
                    
                    // Remove from pending list if needed
                    if let taskId = task.id, let index = pendingLoggedTaskIds.firstIndex(of: taskId) {
                        pendingLoggedTaskIds.remove(at: index)
                    }
                }
            } else {
                offsets.map { loggedTasks[$0] }.forEach { task in
                    taskViewModel.deleteTask(task)
                }
            }
            
            taskUpdateCounter += 1
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
