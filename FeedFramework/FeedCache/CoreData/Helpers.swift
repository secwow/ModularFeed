import CoreData

extension CoreDataCache {
    var localFeed: [LocalFeedImage] {
        return self.feed.compactMap({$0 as? CoreDataFeedImage}).map({$0.local})
    }
    
    static func find(in context: NSManagedObjectContext) throws -> CoreDataCache? {
        let request = NSFetchRequest<CoreDataCache>(entityName: entity().name!)
        request.returnsObjectsAsFaults = false
        let result = try context.fetch(request)
        
        return result.first
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
