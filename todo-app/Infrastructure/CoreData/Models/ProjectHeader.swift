//
//  ProjectHeader.swift
//  todo-app
//
//  Created on 3/26/25.
//

import Foundation
import CoreData

@objc(ProjectHeader)
public class ProjectHeader: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var displayOrder: Int32
    @NSManaged public var project: Project?
    
    /// Validates and ensures all required properties are set correctly
    func validateAndSetDefaults() {
        // Ensure ID is set
        if id == nil {
            id = UUID()
        }
        
        // Ensure title is never nil
        if title == nil {
            title = "Untitled Header"
        }
    }
    
    /// Creates a new ProjectHeader with required properties
    /// - Parameters:
    ///   - context: NSManagedObjectContext to create the header in
    ///   - title: The title of the header
    ///   - project: The project this header belongs to
    ///   - displayOrder: Optional display order (calculated automatically if nil)
    /// - Returns: The newly created ProjectHeader
    static func create(in context: NSManagedObjectContext, title: String, project: Project, displayOrder: Int32? = nil) -> ProjectHeader {
        let header = ProjectHeader(context: context)
        header.id = UUID()
        header.title = title
        header.project = project
        
        // Calculate display order if not provided
        if let order = displayOrder {
            header.displayOrder = order
        } else if let calculatedOrder = header.project?.nextHeaderDisplayOrder() {
            header.displayOrder = calculatedOrder
        } else {
            header.displayOrder = 0
        }
        
        return header
    }
}
