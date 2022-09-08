//
//  Clip+CoreDataProperties.swift
//  ClipperTool
//
//  Created by Tahmid Imran on 8/28/22.
//
//

import Foundation
import CoreData


extension Clip {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Clip> {
        return NSFetchRequest<Clip>(entityName: "Clip")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var value: String?
    @NSManaged public var timeCopied: Date?
    
    var wrappedID: UUID { id! }
    var wrappedValue: String { value ?? "" }
    var wrappedDate: Date { timeCopied! }

}

extension Clip : Identifiable {

}

extension NSManagedObject {

    convenience init(context: NSManagedObjectContext) {
        let name = String(describing: type(of: self))
        let entity = NSEntityDescription.entity(forEntityName: name, in: context)!
        self.init(entity: entity, insertInto: context)
    }

}
