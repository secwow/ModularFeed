import CoreData

extension CoreDataCache {
    var localFeed: [LocalFeedImage] {
        return self.feed.compactMap({$0 as? CoreDataFeedImage}).map({$0.local})
    }
}

extension CoreDataFeedImage {
    var local: LocalFeedImage {
        return LocalFeedImage(id: self.id, description: self.imageDescription, location: self.location, url: self.url)
    }
}
