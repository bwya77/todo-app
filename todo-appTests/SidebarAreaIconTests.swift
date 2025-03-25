//
//  SidebarAreaIconTests.swift
//  todo-appTests
//
//  Created on 3/25/25.
//

import XCTest
import SwiftUI
@testable import todo_app

// Mock ViewInspector functionality for testing
protocol Inspectable {}

extension View {
    func inspect() throws -> InspectableView {
        return InspectableView()
    }
}

class InspectableView {
    func find(text value: String) throws -> TextInspection {
        return TextInspection()
    }
    
    func find(button label: String) throws -> ButtonInspection {
        return ButtonInspection()
    }
    
    func find(image name: String) throws -> ImageInspection {
        return ImageInspection()
    }
}

class TextInspection {
    func opacity() throws -> Double {
        return 1.0
    }
}

class ButtonInspection {
    func find(image name: String) throws -> ImageInspection {
        return ImageInspection()
    }
}

class ImageInspection {
    func opacity() throws -> Double {
        return 1.0
    }
}

extension AreaRowView: Inspectable {}

class SidebarAreaIconTests: XCTestCase {
    
    var mockContext: NSManagedObjectContext!
    
    override func setUpWithError() throws {
        // Create an in-memory Core Data stack for testing
        let persistenceController = PersistenceController(inMemory: true)
        mockContext = persistenceController.container.viewContext
    }
    
    override func tearDownWithError() throws {
        mockContext = nil
    }
    
    // Test that when an area is expanded, only the collapse icon is shown
    func testExpandedAreaShowsOnlyCollapseIcon() throws {
        // Create a test area
        let area = Area(context: mockContext)
        area.id = UUID()
        area.name = "Test Area"
        area.color = "blue"
        area.setValue(5, forKey: "activeTaskCount") // 5 active tasks
        
        // Create view with expanded state
        let view = AreaRowView(
            area: area,
            isSelected: false,
            isExpanded: true, // Expanded
            onSelect: {},
            onToggleExpand: {}
        )
        
        let inspectableView = try view.inspect()
        
        // Verify that the task count is not shown
        XCTAssertThrowsError(try inspectableView.find(text: "5"))
        
        // Verify that the collapse icon (chevron.down) is shown
        let button = try inspectableView.find(button: "Collapse Area")
        let image = try button.find(image: "chevron.down")
        XCTAssertTrue(try image.opacity() == 1.0) // Icon should be visible
    }
    
    // Test that when an area has 0 tasks, only the expand/collapse icon is shown
    func testZeroTasksAreaShowsOnlyExpandCollapseIcon() throws {
        // Create a test area
        let area = Area(context: mockContext)
        area.id = UUID()
        area.name = "Empty Area"
        area.color = "green"
        area.setValue(0, forKey: "activeTaskCount") // 0 active tasks
        
        // Create view with collapsed state
        let view = AreaRowView(
            area: area,
            isSelected: false,
            isExpanded: false, // Collapsed
            onSelect: {},
            onToggleExpand: {}
        )
        
        let inspectableView = try view.inspect()
        
        // Verify that the task count is not shown
        XCTAssertThrowsError(try inspectableView.find(text: "0"))
        
        // Verify that the expand icon (chevron.right) is shown
        let button = try inspectableView.find(button: "Expand Area")
        let image = try button.find(image: "chevron.right")
        XCTAssertTrue(try image.opacity() == 1.0) // Icon should be visible
    }
    
    // Test that when an area has tasks and is collapsed, the task count is shown by default
    func testCollapsedAreaWithTasksShowsCount() throws {
        // Create a test area
        let area = Area(context: mockContext)
        area.id = UUID()
        area.name = "Busy Area"
        area.color = "red"
        area.setValue(10, forKey: "activeTaskCount") // 10 active tasks
        
        // Create view with collapsed state
        let view = AreaRowView(
            area: area,
            isSelected: false,
            isExpanded: false, // Collapsed
            onSelect: {},
            onToggleExpand: {}
        )
        
        let inspectableView = try view.inspect()
        
        // Verify that the task count is shown
        let countText = try inspectableView.find(text: "10")
        XCTAssertTrue(try countText.opacity() == 1.0) // Task count should be visible
        
        // Verify that the expand icon exists but is not visible by default
        let button = try inspectableView.find(button: "Expand Area")
        let image = try button.find(image: "chevron.right")
        XCTAssertTrue(try image.opacity() == 0.0) // Icon should be hidden
    }
}
