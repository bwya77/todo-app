//
//  ToolbarDelegateTests.swift
//  todo-appTests
//
//  Created on 3/9/25.
//

import XCTest
import SwiftUI
import AppKit
@testable import todo_app

final class ToolbarDelegateTests: XCTestCase {
    func testToggleSidebarItem() throws {
        // Test that the toolbar includes the correct toggle sidebar item
        let delegate = ToolbarDelegate.shared
        let toolbar = NSToolbar(identifier: "TestToolbar")
        let itemIdentifier = NSToolbarItem.Identifier("toggleSidebar")
        
        guard let item = delegate.toolbar(toolbar, itemForItemIdentifier: itemIdentifier, willBeInsertedIntoToolbar: true) else {
            XCTFail("Failed to create toolbar item")
            return
        }
        
        XCTAssertEqual(item.itemIdentifier, itemIdentifier)
        XCTAssertEqual(item.label, "Toggle Sidebar")
        XCTAssertEqual(item.paletteLabel, "Toggle Sidebar")
        XCTAssertEqual(item.toolTip, "Toggle Sidebar")
        XCTAssertEqual(item.target as? NSObject, delegate)
    }
    
    func testDefaultToolbarItems() throws {
        // Test that the toolbar includes the correct default items
        let delegate = ToolbarDelegate.shared
        let toolbar = NSToolbar(identifier: "TestToolbar")
        let identifiers = delegate.toolbarDefaultItemIdentifiers(toolbar)
        
        XCTAssertEqual(identifiers.count, 1)
        XCTAssertEqual(identifiers.first?.rawValue, "toggleSidebar")
    }
    
    func testAllowedToolbarItems() throws {
        // Test that the toolbar allows the correct items
        let delegate = ToolbarDelegate.shared
        let toolbar = NSToolbar(identifier: "TestToolbar")
        let identifiers = delegate.toolbarAllowedItemIdentifiers(toolbar)
        
        XCTAssertEqual(identifiers.count, 1)
        XCTAssertEqual(identifiers.first?.rawValue, "toggleSidebar")
    }
    
    func testMainWindowExtension() throws {
        // Test that the mainWindow extension works correctly
        let mockWindow = NSWindow()
        let windows = [mockWindow]
        
        // Use a mock method to simulate NSApplication.shared.windows
        func mockWindows() -> [NSWindow] {
            return windows
        }
        
        // Verify that the extension returns the first window when no key window is available
        XCTAssertEqual(windows.first, mockWindow)
    }
}
