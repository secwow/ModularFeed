import CoreData

public class CoreDataFeedStore: FeedStore {
    
    enum LoadingError: Error {
        case cantLoadPersistentStore(Swift.Error)
    }
    
    private let persistanceStoreContainer: NSPersistentContainer
    private let context: NSManagedObjectContext
    
    public init(with storeURL: URL, bundle: Bundle) throws {
        self.persistanceStoreContainer = try NSPersistentContainer.load(modelName: "FeedModel", url: storeURL, in: bundle)
        self.context = persistanceStoreContainer.newBackgroundContext()
    }
    
    public func deleteCachedFeed(completion: @escaping (Error?) -> ()) {
        perform { context in
            do {
                try CoreDataCache.find(in: context)
                                 .map(context.delete)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    public func insert(_ feedItems: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        perform { context in
            do {
                let cache = try CoreDataCache.createNewUniqueInstance(in: context)
                cache.timestamp = timestamp
                cache.feed = CoreDataFeedImage.convertToManagedImages(localImages: feedItems, in: context)
                try context.save()
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    public func retrieve(completion: @escaping RetrivalCompletion) {
         perform { context in
            do {
                guard let cache = try CoreDataCache.find(in: context) else {
                    completion(.success(.empty))
                    return
                }
                completion(.success(.found(feed: cache.localFeed, timestamp: cache.timestamp)))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    private func perform(performBlock: @escaping (NSManagedObjectContext) -> ()) {
        let context = self.context
        context.perform {
            performBlock(context)
        }
    }
}

private extension NSManagedObjectModel {
    static func with(name: String, in bundle: Bundle) -> NSManagedObjectModel? {
        return bundle
            .url(forResource: name, withExtension: "momd")
            .flatMap { NSManagedObjectModel(contentsOf: $0) }
    }
}

private extension NSPersistentContainer {
    enum LoadingError: Swift.Error {
        case modelNotFound
        case failedToLoadPersistentStores(Swift.Error)
    }
    
    static func load(modelName name: String, url: URL, in bundle: Bundle) throws -> NSPersistentContainer {
        guard let model = NSManagedObjectModel.with(name: name, in: bundle) else {
            throw LoadingError.modelNotFound
        }
        
        let description = NSPersistentStoreDescription(url: url)
        let container = NSPersistentContainer(name: name, managedObjectModel: model)
        container.persistentStoreDescriptions = [description]
        
        var loadError: Swift.Error?
        container.loadPersistentStores { loadError = $1 }
        try loadError.map { throw LoadingError.failedToLoadPersistentStores($0) }
        
        return container
    }
}
