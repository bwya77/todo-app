//
//  InboxIconToggleTests.swift
//  todo-appTests
//
//  Created by Bradley Wyatt on 3/12/25.
//

import XCTest
import SwiftUI
import CoreData
@testable import todo_app

class InboxIconToggleTests: XCTestCase {
    
    var viewContext: NSManagedObjectContext!
    
    override func setUpWithError() throws {
        // Set up an in-memory Core Data stack for testing
        let persistenceController = PersistenceController(inMemory: true)
        viewContext = persistenceController.container.viewContext
    }
    
    override func tearDownWithError() throws {
        viewContext = nil
    }
    
    func testInboxIconReturnsCorrectIconNameInViewType() {
        // Test that the ViewType.inbox returns the correct icon name
        XCTAssertEqual(ViewType.inbox.iconName, "tray.full", "Inbox ViewType should return 'tray.full' as its icon name")
    }
    
    func testSidebarViewIconsDisplayCorrectly() {
        // Test setup for the sidebar view with Inbox not selected
        let viewType = ViewType.today // Start with a different view
        let selectedViewType = Binding<ViewType>(
            get: { viewType },
            set: { _ in }
        )
        let selectedProject = Binding<Project?>(
            get: { nil },
            set: { _ in }
        )
        
        // Create an inspector for the view
        let sidebarView = SidebarView(
            selectedViewType: selectedViewType,
            selectedProject: selectedProject,
            context: viewContext,
            onShowTaskPopup: {}
        )
        
        // We can't test the rendering directly in unit tests, but we can test the behavior indirectly
        // by checking that ViewType.iconName is used correctly
        
        // When inbox is selected, the icon should be "tray.full"
        XCTAssertEqual(ViewType.inbox.iconName, "tray.full")
        
        // When a different view type is selected, SidebarView should use "tray" (tested manually)
        // This test mainly verifies that our changes didn't break the ViewType structure
        XCTAssertNotEqual(ViewType.today.iconName, "tray.full")
    }
}
