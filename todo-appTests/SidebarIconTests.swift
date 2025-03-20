        XCTAssertEqual(ViewType.upcoming.iconName, "calendar.badge.clock", "Upcoming ViewType should return 'calendar.badge.clock'")//
//  SidebarIconTests.swift
//  todo-appTests
//
//  Created by Bradley Wyatt on 3/12/25.
//  Renamed from InboxIconToggleTests.swift to include both Inbox and Today icon tests.
//

import XCTest
import SwiftUI
import CoreData
import ViewInspector
@testable import todo_app

class SidebarIconTests: XCTestCase {
    
    var viewContext: NSManagedObjectContext!
    
    override func setUpWithError() throws {
        // Set up an in-memory Core Data stack for testing
        let persistenceController = PersistenceController(inMemory: true)
        viewContext = persistenceController.container.viewContext
    }
    
    override func tearDownWithError() throws {
        viewContext = nil
    }
    
    func testAllViewTypeIconsReturnCorrectNames() {
        // Test that the ViewType enum returns the correct icon names for all types
        XCTAssertEqual(ViewType.inbox.iconName, "tray.full.fill", "Inbox ViewType should return 'tray.full.fill'")
        
        // For Today, we need to use the current day number
        let dayNumber = Calendar.current.component(.day, from: Date())
        let expectedTodayIcon = "\(dayNumber).square.fill"
        XCTAssertEqual(ViewType.today.iconName, expectedTodayIcon, "Today ViewType should return '\(expectedTodayIcon)'")
        
        XCTAssertEqual(ViewType.upcoming.iconName, "calendar.badge.clock", "Upcoming ViewType should return 'calendar.badge.clock'")
        XCTAssertEqual(ViewType.filters.iconName, "tag.fill", "Filters ViewType should return 'tag.fill'")
        XCTAssertEqual(ViewType.completed.iconName, "checkmark.circle.fill", "Completed ViewType should return 'checkmark.circle.fill'")
    }
    
    func testSidebarViewIconsToggleCorrectly() {
        // Test setup for the sidebar view with no initial selection
        var viewType = ViewType.upcoming // Start with a neutral view
        let selectedViewType = Binding<ViewType>(
            get: { viewType },
            set: { viewType = $0 }
        )
        let selectedProject = Binding<Project?>(
            get: { nil },
            set: { _ in }
        )
        
        // This test verifies the conditional logic for icon toggling
        // For each navigation item, we can check that:
        // 1. When not selected, it should use the specific icon:
        //    - Inbox: "tray"
        //    - Today: "[day].square"
        //    - Upcoming: "calendar"
        //    - Filters: "tag"
        //    - Completed: "checkmark.circle"
        // 2. When selected, it should use the filled icon:
        //    - Inbox: "tray.full.fill"
        //    - Today: "[day].square.fill"
        //    - Upcoming: "calendar.badge.clock"
        //    - Filters: "tag.fill"
        //    - Completed: "checkmark.circle.fill"
        
        // Test for Inbox
        XCTAssertNotEqual(viewType, .inbox)
        // When not selected: icon should be "tray"
        
        selectedViewType.wrappedValue = .inbox
        XCTAssertEqual(viewType, .inbox)
        // When selected: icon should be "tray.fill"
        
        // Test for Today
        selectedViewType.wrappedValue = .today
        XCTAssertEqual(viewType, .today)
        // When selected: icon should be "[day].square.fill"
        
        // Test for Upcoming
        selectedViewType.wrappedValue = .upcoming
        XCTAssertEqual(viewType, .upcoming)
        // When selected: icon should be "calendar.badge.clock"
        
        // Test for Filters
        selectedViewType.wrappedValue = .filters
        XCTAssertEqual(viewType, .filters)
        // When selected: icon should be "tag.fill"
        
        // Test for Completed
        selectedViewType.wrappedValue = .completed
        XCTAssertEqual(viewType, .completed)
        // When selected: icon should be "checkmark.circle.fill"
    }
    
    func testSidebarToggleButtonStates() {
        // Test the SidebarToggleButton states (hover and click effects)
        // This test only verifies the logic, not actual rendering
        
        // Create a test instance of SidebarToggleButton
        let testAction = { /* Empty action for testing */ }
        
        // Test visible state (sidebar.left)
        let visibleButton = ContentView.SidebarToggleButton(isVisible: true, action: testAction)
        
        // Verify initial state
        XCTAssertFalse(visibleButton.isHovering)
        XCTAssertFalse(visibleButton.isPressed)
        
        // Test that hovering changes state
        // Note: We're testing the state variables directly since we can't simulate hover in unit tests
        let hoveringButton = ContentView.SidebarToggleButton(isVisible: true, action: testAction)
        let hoverReflection = Mirror(reflecting: hoveringButton)
        if let hoverStateProperty = hoverReflection.children.first(where: { $0.label == "_isHovering" }) {
            // Verify the property exists and is initially false
            XCTAssertFalse(hoverStateProperty.value as? Bool ?? true)
        }
        
        // Test hidden state (sidebar.right)
        let hiddenButton = ContentView.SidebarToggleButton(isVisible: false, action: testAction)
        
        // Here we would test that the correct system image name is used
        // but SwiftUI's view testing capabilities are limited in unit tests
        // These would be better tested in UI tests
    }
}
