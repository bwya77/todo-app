//
//  Project+Extensions.swift
//  todo-app
//
//  Created on 3/19/25.
//

import Foundation
import CoreData

extension Project {
    // Add a computed property for lastModifiedDate since it's not in the Core Data model
    @objc var lastModifiedDate: Date? {
        get {
            return UserDefaults.standard.object(forKey: "project_last_modified_\(id?.uuidString ?? "unknown")") as? Date
        }
        set {
            if let id = id?.uuidString, let newValue = newValue {
                UserDefaults.standard.set(newValue, forKey: "project_last_modified_\(id)")
            }
        }
    }
}
