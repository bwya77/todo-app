//
//  ProjectHeader+FetchRequests.swift
//  todo-app
//
//  Created on 3/26/25.
//

import Foundation
import CoreData

extension ProjectHeader {
    static func fetchRequest() -> NSFetchRequest<ProjectHeader> {
        return NSFetchRequest<ProjectHeader>(entityName: "ProjectHeader")
    }
}
