//
//  ProjectNotesEditor.swift
//  todo-app
//
//  Created on 3/13/25.
//

import SwiftUI
import AppKit
import Cocoa

struct ProjectNotesEditor: View {
    @Binding var text: String
    let placeholder: String
    let font: Font
    
    @FocusState private var isFocused: Bool
    
    // Make sure the text view's default height is always single line
    private let defaultLineHeight: CGFloat = 22
    
    init(text: Binding<String>, placeholder: String = "Notes", font: Font = .body) {
        self._text = text
        self.placeholder = placeholder
        self.font = font
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Placeholder text
            if text.isEmpty && !isFocused {
                Text(placeholder)
                    .font(font)
                    .foregroundColor(Color.gray.opacity(0.5))
                    .allowsHitTesting(false)
                    .padding(.horizontal, 2)
                    .padding(.top, 2)
                    .zIndex(1)
            }
            
            // Text editor with auto-height adjustment and growth direction downward
            TextEditorWithShiftEnter(text: $text, font: font)
                .focused($isFocused)
                .frame(height: calculateHeight())
                .foregroundColor(.black)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }
    
    // Calculate height based on content
    private func calculateHeight() -> CGFloat {
        // Count number of lines based on newline characters
        let lineCount = text.components(separatedBy: "\n").count
        
        // Also account for word wrapping
        // We're estimating an average of 80 characters per line at standard font sizes
        let averageCharsPerLine = 80.0
        let wrappedLineEstimate = text.count / Int(averageCharsPerLine)
        
        // Use the greater of actual line breaks or estimated wrapped lines
        let totalLines = max(lineCount, wrappedLineEstimate + 1)
        
        // Calculate height based on number of lines
        let calculatedHeight = CGFloat(totalLines) * defaultLineHeight
        
        // Return at least defaultLineHeight, at most 5 lines (or adjust as needed)
        return min(max(defaultLineHeight, calculatedHeight), defaultLineHeight * 5)
    }
}

// Custom TextEditor with ShiftEnter handling
struct TextEditorWithShiftEnter: NSViewRepresentable {
    @Binding var text: String
    var font: Font
    
    func makeNSView(context: Context) -> NSScrollView {
        // Create a scroll view to contain the text view
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .noBorder
        scrollView.backgroundColor = NSColor.clear
        
        // Create the text view
        let textView = NSTextView(frame: scrollView.bounds)
        textView.delegate = context.coordinator
        
        // Configure text view for proper expansion
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.minSize = NSSize(width: 0, height: 0)
        textView.autoresizingMask = [.width]
        
        // Configure text container for proper expansion
        if let textContainer = textView.textContainer {
            textContainer.widthTracksTextView = true
            textContainer.containerSize = NSSize(
                width: scrollView.contentSize.width,
                height: CGFloat.greatestFiniteMagnitude
            )
            textContainer.lineFragmentPadding = 0
        }
        
        // Apply styling for minimal appearance
        textView.isRichText = false
        textView.drawsBackground = false
        textView.textContainerInset = .zero
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        
        // Apply font and set initial content
        if let nsFont = font.nsFont {
            textView.font = nsFont
        } else {
            textView.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        }
        
        // Set content and make it unique to this instance
        textView.string = text
        textView.setAccessibilityIdentifier("ProjectNotes_\(UUID().uuidString)")
        
        // Configure the scroll view with the text view
        scrollView.documentView = textView
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        
        // Update text if it changed externally and isn't being edited
        if textView.string != text && scrollView.window?.firstResponder != textView {
            textView.string = text
        }
        
        // Apply font when updating
        if let nsFont = font.nsFont {
            textView.font = nsFont
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: TextEditorWithShiftEnter
        
        init(_ parent: TextEditorWithShiftEnter) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            DispatchQueue.main.async {
                self.parent.text = textView.string
            }
        }
        
        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            // Handle Enter key to add a new line instead of ending editing
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                // Insert a new line
                textView.insertText("\n", replacementRange: textView.selectedRange)
                return true
            }
            
            // Let other commands be handled as normal
            return false
        }
    }
}

// Extension to convert SwiftUI Font to NSFont
extension Font {
    var nsFont: NSFont? {
        switch self {
        case .largeTitle:
            return NSFont.systemFont(ofSize: NSFont.systemFontSize * 2.0, weight: .regular)
        case .title:
            return NSFont.systemFont(ofSize: NSFont.systemFontSize * 1.5, weight: .regular)
        case .headline:
            return NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .bold)
        case .subheadline:
            return NSFont.systemFont(ofSize: NSFont.systemFontSize * 0.9, weight: .regular)
        case .body:
            return NSFont.systemFont(ofSize: NSFont.systemFontSize)
        case .callout:
            return NSFont.systemFont(ofSize: NSFont.systemFontSize * 0.85)
        case .footnote:
            return NSFont.systemFont(ofSize: NSFont.systemFontSize * 0.8)
        case .caption:
            return NSFont.systemFont(ofSize: NSFont.systemFontSize * 0.7)
        default:
            return NSFont.systemFont(ofSize: NSFont.systemFontSize)
        }
    }
}
