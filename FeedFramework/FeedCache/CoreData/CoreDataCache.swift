import CoreData

@objc(CoreDataCache)
class CoreDataCache: NSManagedObject {
    @NSManaged var timestamp: Date
    @NSManaged var feed: NSOrderedSet
}
