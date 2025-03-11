//
//  CircleProgressAnimatorTests.swift
//  todo-appTests
//
//  Created on 3/11/25.
//

import XCTest
@testable import todo_app

final class CircleProgressAnimatorTests: XCTestCase {
    
    var animator: CircleProgressAnimator!
    
    override func setUp() {
        super.setUp()
        animator = CircleProgressAnimator()
    }
    
    override func tearDown() {
        animator = nil
        super.tearDown()
    }
    
    func testInitialProgress() {
        // Test that initial progress is zero
        XCTAssertEqual(animator.currentProgress, 0.0)
        XCTAssertEqual(animator.targetProgress, 0.0)
    }
    
    func testSetProgress() {
        // Test immediate progress setting
        animator.setProgress(0.5)
        XCTAssertEqual(animator.currentProgress, 0.5)
        XCTAssertEqual(animator.targetProgress, 0.5)
        
        // Test value clamping for values > 1.0
        animator.setProgress(1.5)
        XCTAssertEqual(animator.currentProgress, 1.0)
        XCTAssertEqual(animator.targetProgress, 1.0)
        
        // Test value clamping for values < 0.0
        animator.setProgress(-0.5)
        XCTAssertEqual(animator.currentProgress, 0.0)
        XCTAssertEqual(animator.targetProgress, 0.0)
    }
    
    func testReset() {
        // Set some progress
        animator.setProgress(0.7)
        XCTAssertEqual(animator.currentProgress, 0.7)
        
        // Reset should set both values to 0
        animator.reset()
        XCTAssertEqual(animator.currentProgress, 0.0)
        XCTAssertEqual(animator.targetProgress, 0.0)
    }
    
    func testAnimationStart() {
        // Test that animation starts with correct target
        animator.animateTo(0.8)
        XCTAssertEqual(animator.targetProgress, 0.8)
        
        // Initially, current progress should still be 0
        XCTAssertEqual(animator.currentProgress, 0.0)
        
        // Allow some time for animation to progress
        let expectation = XCTestExpectation(description: "Animation starts")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Current progress should have moved toward target
            XCTAssertGreaterThan(self.animator.currentProgress, 0.0)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 0.2)
    }
    
    func testAnimationCompletion() {
        // Test that animation eventually reaches target
        animator.animateTo(0.5)
        
        // Wait for animation to complete
        let expectation = XCTestExpectation(description: "Animation completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Current progress should equal target
            XCTAssertEqual(self.animator.currentProgress, 0.5, accuracy: 0.01)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.5)
    }
    
    func testAnimationCancellation() {
        // Start an animation
        animator.animateTo(0.8)
        
        // Then immediately start a new one
        animator.animateTo(0.3)
        
        // Target should be updated
        XCTAssertEqual(animator.targetProgress, 0.3)
        
        // Wait for animation to complete
        let expectation = XCTestExpectation(description: "Animation reaches new target")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Current progress should approach second target, not first
            XCTAssertEqual(self.animator.currentProgress, 0.3, accuracy: 0.01)
            XCTAssertNotEqual(self.animator.currentProgress, 0.8, accuracy: 0.1)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.5)
    }
}
