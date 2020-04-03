import CoreData

@objc(CoreDataFeedImage)
class CoreDataFeedImage: NSManagedObject {
    @NSManaged internal var id: UUID
    @NSManaged internal var imageDescription: String?
    @NSManaged internal var location: String?
    @NSManaged internal var url: URL
    @NSManaged internal var cache: CoreDataCache
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
