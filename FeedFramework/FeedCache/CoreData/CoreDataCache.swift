import CoreData

@objc(CoreDataCache)
class CoreDataCache: NSManagedObject {
    @NSManaged internal var timestamp: Date
    @NSManaged internal var feed: NSOrderedSet
}
