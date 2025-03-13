//
//  NSManagedObject+Validation.swift
//  todo-app
//
//  Created on 3/12/25.
//

import Foundation
import CoreData

extension NSManagedObject {
    /// Apply validation rules before saving
    /// - Returns: True if validation succeeded, false otherwise
    @discardableResult
    func validateBeforeSave() -> Bool {
        // Call entity-specific validation methods if available
        if let item = self as? Item {
            item.validateAndSetDefaults()
        } else if let project = self as? Project {
            project.validateAndSetDefaults()
        } else if let tag = self as? Tag {
            tag.validateAndSetDefaults()
        }
        
        // Perform standard CoreData validation
        do {
            try validateForUpdate()
            return true
        } catch {
            print("Validation error for \(entity.name ?? "unknown entity"): \(error)")
            return false
        }
    }
}

extension NSManagedObjectContext {
    /// Register for save notifications to ensure validation
    func registerForValidationOnSave() {
        // Remove any existing notification observers
        NotificationCenter.default.removeObserver(self, name: .NSManagedObjectContextWillSave, object: self)
        
        // Add notification observer for validation before save
        NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextWillSave,
            object: self,
            queue: nil) { [weak self] notification in
                guard let context = self else {
                    return
                }
                
                // Validate all new and updated objects
                let allObjects = context.insertedObjects.union(context.updatedObjects)
                for object in allObjects {
                    _ = object.validateBeforeSave()
                }
            }
    }
}

// MARK: - Save Notifications

extension Notification.Name {
    /// Notification sent after successful save
    static let didSaveWithSuccess = Notification.Name("com.todoapp.context.didSaveWithSuccess")
    
    /// Notification sent after failed save
    static let didSaveWithError = Notification.Name("com.todoapp.context.didSaveWithError")
}

extension NSManagedObjectContext {
    /// Save with notifications for success/failure
    @discardableResult
    func saveWithNotification() -> Bool {
        do {
            // Only save if there are changes
            guard hasChanges else { return true }
            
            try save()
            NotificationCenter.default.post(name: .didSaveWithSuccess, object: self)
            return true
        } catch {
            print("Error saving context: \(error)")
            NotificationCenter.default.post(
                name: .didSaveWithError,
                object: self,
                userInfo: ["error": error]
            )
            return false
        }
    }
}
