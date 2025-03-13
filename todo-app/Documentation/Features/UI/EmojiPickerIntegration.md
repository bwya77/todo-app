This guide explains how we solved a tricky issue with macOS emoji picker integration in our SwiftUI/AppKit hybrid To-Do application.

## The Problem
We implemented a feature allowing users to edit project titles by clicking on them. The feature had an issue related to the emoji picker:
1. When a user clicked a project title and activated editing mode, they could use ⌘+⌃+Space (or Fn/Globe key) to bring up the emoji picker.
2. We encountered two specific issues:
    - **First Issue**: When a user inserted an emoji, editing would stop immediately.
    - **Second Issue**: When a user brought up the emoji picker but clicked away without selecting an emoji, the text field would remain in an editing state forever.

## Understanding the Challenge
Working with macOS emoji picker in SwiftUI/AppKit hybrid applications is challenging because:
1. The emoji picker operates in its own window.
2. When the emoji picker is activated, focus temporarily shifts away from the text field.
3. Various events fire in a complex sequence when using the emoji picker.
4. SwiftUI and AppKit have different event handling systems.

## The Solution
We implemented a solution that correctly tracks emoji picker state and prevents unwanted saving behavior:

### 1. Track Emoji Picker State

```swift
class GlobalClickMonitor {
    static let shared = GlobalClickMonitor()
    // ...
    
    // Simple flag to track emoji picker state
    var isEmojiPickerActive = false
    // ...
}
```

### 2. Detect Emoji Picker Activation
We detect when the user activates the emoji picker through keyboard shortcuts:

```swift
// In GlobalClickMonitor.startMonitoring()
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
```

### 3. Custom Click Handling
The key innovation is in how we handle clicks when the emoji picker is active:

```swift
// For global clicks (outside the app)
globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] _ in
    guard let self = self else { return }
    
    // Ignore clicks while emoji picker is active (give it time to complete)
    if self.isEmojiPickerActive {
        return
    }
    
    // Normal click outside - trigger callback
    self.onClickOutside?()
}

// For local clicks (inside the app)
localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown]) { [weak self, weak view] event in
    // ...
    
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
    
    // ... normal click handling ...
}
```

### 4. Prevent Premature Saving During Emoji Insertion

```swift
// In text field delegate's controlTextDidEndEditing
func controlTextDidEndEditing(_ obj: Notification) {
    // Check for emoji picker state to handle emoji insertion
    if GlobalClickMonitor.shared.isEmojiPickerActive {
        // Don't commit changes if emoji picker was active
        return
    }
    
    // Regular end editing - commit the changes
    parent.onCommit()
}
```

### 5. Delay Title Saving When Emoji Picker Is Active

```swift
private func saveProjectTitle() {
    guard isEditingTitle else { return }
    
    // Don't save or stop editing if emoji picker might be active
    if clickMonitor.isEmojiPickerActive {
        // We don't want to save while emoji picker is active
        return
    }
    
    finalizeSaveProjectTitle()
}
```

## Key Design Principles
1. **State Tracking**: We track the emoji picker state with a simple boolean flag.
2. **Non-Interruption**: We prevent the app from saving or committing changes while the emoji picker is active.
3. **Window-Based Detection**: We specifically check for clicks in the emoji picker window to handle it differently.
4. **Clear Flag on Click**: We only clear the emoji picker state when the user clicks outside the emoji picker window.
5. **Delayed Saving**: We delay saving until we're sure the emoji picker interaction is complete.

## The Flow in Action
1. **User starts editing a title**
    - Sets `isEditingTitle = true`
    - Text field becomes editable
2. **User activates emoji picker (⌘+⌃+Space or Globe key)**
    - Sets `isEmojiPickerActive = true`
3. **Scenario A - User selects an emoji**
    - Click is in emoji picker window -> we don't reset `isEmojiPickerActive`
    - Emoji gets inserted into text field
    - User continues editing or clicks elsewhere to save
4. **Scenario B - User clicks away without selecting emoji**
    - The click occurs outside emoji picker window
    - We reset `isEmojiPickerActive = false` but don't immediately save
    - On next click outside the text field, we properly save the title

## Benefits of This Approach
1. **No Timers/Delays**: We avoid arbitrary timeouts that could disrupt user experience.
2. **Simple Flag-Based Logic**: Makes the code easier to understand and maintain.
3. **Natural User Experience**: Users can add emojis and continue editing naturally.
4. **Proper Click-Away Handling**: Prevents the text field from getting stuck in editing mode.

This solution creates a seamless experience for users who want to add emojis to their project titles while maintaining robust text field behavior.