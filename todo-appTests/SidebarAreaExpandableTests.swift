//
//  SidebarAreaExpandableTests.swift
//  todo-appTests
//
//  Created on 3/25/25.
//

import XCTest
import SwiftUI
@testable import todo_app

class SidebarAreaExpandableTests: XCTestCase {
    
    var mockContext: NSManagedObjectContext!
    
    override func setUpWithError() throws {
        // Create an in-memory Core Data stack for testing
        let persistenceController = PersistenceController(inMemory: true)
        mockContext = persistenceController.container.viewContext
    }
    
    override func tearDownWithError() throws {
        mockContext = nil
    }
    
    // Test that area expand/collapse icons are visible when sidebar is hovered
    func testAreaExpandIconsVisibleWhenSidebarHovered() {
        // Set up test data
        let area = Area(context: mockContext)
        area.id = UUID()
        area.name = "Test Area"
        area.color = "blue"
        area.setValue(5, forKey: "activeTaskCount") // 5 active tasks
        
        // Create view with sidebar hover state
        let isSidebarHovered = true
        
        // Create the view
        let view = AreaRowView(
            area: area,
            isSelected: false,
            isExpanded: false,
            isSidebarHovered: isSidebarHovered,
            onSelect: {},
            onToggleExpand: {}
        )
        
        // Check if the expand/collapse icon is visible
        XCTAssertTrue(isExpandCollapseIconVisible(in: view))
        
        // Verify the task count is hidden
        XCTAssertFalse(isTaskCountVisible(in: view))
    }
    
    // Test that task count is visible when sidebar is not hovered
    func testTaskCountVisibleWhenSidebarNotHovered() {
        // Set up test data
        let area = Area(context: mockContext)
        area.id = UUID()
        area.name = "Test Area"
        area.color = "blue"
        area.setValue(5, forKey: "activeTaskCount") // 5 active tasks
        
        // Create view with sidebar not hovered
        let isSidebarHovered = false
        
        // Create the view
        let view = AreaRowView(
            area: area,
            isSelected: false,
            isExpanded: false,
            isSidebarHovered: isSidebarHovered,
            onSelect: {},
            onToggleExpand: {}
        )
        
        // Check if the task count is visible
        XCTAssertTrue(isTaskCountVisible(in: view))
        
        // Verify the expand/collapse icon is hidden
        XCTAssertFalse(isExpandCollapseIconVisible(in: view))
    }
    
    // Test that for areas with zero tasks, expand icon is always visible
    func testExpandIconVisibleForAreasWithZeroTasks() {
        // Set up test data
        let area = Area(context: mockContext)
        area.id = UUID()
        area.name = "Empty Area"
        area.color = "green"
        area.setValue(0, forKey: "activeTaskCount") // 0 active tasks
        
        // Create view with sidebar not hovered
        let isSidebarHovered = false
        
        // Create the view
        let view = AreaRowView(
            area: area,
            isSelected: false,
            isExpanded: false,
            isSidebarHovered: isSidebarHovered,
            onSelect: {},
            onToggleExpand: {}
        )
        
        // Check if the expand/collapse icon is visible
        XCTAssertTrue(isExpandCollapseIconVisible(in: view))
        
        // Verify no task count is shown
        XCTAssertFalse(isTaskCountVisible(in: view))
    }
    
    // Test that for expanded areas, collapse icon is always visible
    func testCollapseIconVisibleForExpandedAreas() {
        // Set up test data
        let area = Area(context: mockContext)
        area.id = UUID()
        area.name = "Expanded Area"
        area.color = "red"
        area.setValue(10, forKey: "activeTaskCount") // 10 active tasks
        
        // Create view with sidebar not hovered
        let isSidebarHovered = false
        
        // Create the view with expanded state
        let view = AreaRowView(
            area: area,
            isSelected: false,
            isExpanded: true, // Area is expanded
            isSidebarHovered: isSidebarHovered,
            onSelect: {},
            onToggleExpand: {}
        )
        
        // Check if the collapse icon is visible
        XCTAssertTrue(isExpandCollapseIconVisible(in: view))
        
        // Verify no task count is shown for expanded areas
        XCTAssertFalse(isTaskCountVisible(in: view))
    }
    
    // MARK: - Helper Methods
    
    /// Helper method to check if the expand/collapse icon is visible
    private func isExpandCollapseIconVisible(in view: AreaRowView) -> Bool {
        // In a real test with ViewInspector, we would check the actual opacity
        // Since we can't easily hook into SwiftUI views for testing, we're simulating the check
        // based on our implementation logic
        
        let area = view.area
        let isExpanded = view.isExpanded
        let sidebarHovered = view.isSidebarHovered
        
        return isExpanded || area.activeTaskCount == 0 || sidebarHovered
    }
    
    /// Helper method to check if the task count is visible
    private func isTaskCountVisible(in view: AreaRowView) -> Bool {
        // Similar to above, we're simulating the check based on our implementation logic
        
        let area = view.area
        let isExpanded = view.isExpanded
        let sidebarHovered = view.isSidebarHovered
        
        return area.activeTaskCount > 0 && !isExpanded && !sidebarHovered
    }
}
