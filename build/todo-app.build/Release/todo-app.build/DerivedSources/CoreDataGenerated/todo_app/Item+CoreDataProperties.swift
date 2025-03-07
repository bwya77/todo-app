//
//  Item+CoreDataProperties.swift
//  
//
//  Created by Bradley Wyatt on 3/7/25.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Item {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Item> {
        return NSFetchRequest<Item>(entityName: "Item")
    }

    @NSManaged public var completed: Bool
    @NSManaged public var createdDate: Date?
    @NSManaged public var dueDate: Date?
    @NSManaged public var isAllDay: Bool
    @NSManaged public var id: UUID?
    @NSManaged public var notes: String?
    @NSManaged public var priority: Int16
    @NSManaged public var title: String?
    @NSManaged public var project: Project?
    @NSManaged public var tags: NSSet?

}

// MARK: Generated accessors for tags
extension Item {

    @objc(addTagsObject:)
    @NSManaged public func addToTags(_ value: Tag)

    @objc(removeTagsObject:)
    @NSManaged public func removeFromTags(_ value: Tag)

    @objc(addTags:)
    @NSManaged public func addToTags(_ values: NSSet)

    @objc(removeTags:)
    @NSManaged public func removeFromTags(_ values: NSSet)

}

extension Item : Identifiable {

}
