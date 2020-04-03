import CoreData

@objc(CoreDataCache)
internal class CoreDataCache: NSManagedObject {
    @NSManaged internal var timestamp: Date
    @NSManaged internal var feed: NSOrderedSet
}
