import CoreData

extension CoreDataCache {
    var localFeed: [LocalFeedImage] {
        return self.feed.compactMap({$0 as? CoreDataFeedImage}).map({$0.local})
    }
    
    static func find(in context: NSManagedObjectContext) throws -> CoreDataCache? {
        let request = NSFetchRequest<CoreDataCache>(entityName: self.entity().name!)
        request.returnsObjectsAsFaults = false
        return try context.fetch(request).first
    }
    
    static func createNewUniqueInstance(in context: NSManagedObjectContext) throws -> CoreDataCache {
        try find(in: context).map(context.delete)
        return CoreDataCache(context: context)
    }
}

extension CoreDataFeedImage {
    var local: LocalFeedImage {
        return LocalFeedImage(id: self.id, description: self.imageDescription, location: self.location, url: self.url)
    }
}
