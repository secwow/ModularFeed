import CoreData

@objc(CoreDataFeedImage)
class CoreDataFeedImage: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var imageDescription: String?
    @NSManaged var location: String?
    @NSManaged var url: URL
    @NSManaged var cache: CoreDataCache
}

extension CoreDataFeedImage {
    static func convertToManagedImages(localImages: [LocalFeedImage], in context: NSManagedObjectContext) -> NSOrderedSet {
        return NSOrderedSet(array: localImages.map({ localImage in
            let feedImage = CoreDataFeedImage(context: context)
            feedImage.id = localImage.id
            feedImage.location = localImage.location
            feedImage.imageDescription = localImage.description
            feedImage.url = localImage.url
            return feedImage
        }))
    }
}
