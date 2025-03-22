//
//  Displayable.swift
//  todo-app
//
//  Created on 3/22/25.
//

import Foundation
import CoreData

/// Protocol for objects that can be displayed in order
protocol Displayable {
    /// The display order attribute name
    static var orderAttributeName: String { get }
    
    /// Get the display order
    func getDisplayOrder() -> Int32
    
    /// Set the display order
    func setDisplayOrder(_ newValue: Int32)
    
    /// Update display order and persist changes
    func updateDisplayOrder(_ newOrder: Int32, save: Bool)
}
