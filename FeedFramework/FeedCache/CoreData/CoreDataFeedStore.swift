//
//  CoreDataFeedStore.swift
//  FeedFramework
//
//  Created by AndAdmin on 03.04.2020.
//  Copyright © 2020 AndAdmin. All rights reserved.
//

import CoreData

public class CoreDataFeedStore: FeedStore {
    
    enum LoadingError: Error {
        case cantLoadPersistentStore(Swift.Error)
    }
    
    private let persistanceStoreContainer: NSPersistentContainer
    private let context: NSManagedObjectContext
    
    public init(with storeURL: URL, modelName: String, bundle: Bundle) throws {
        self.persistanceStoreContainer = try NSPersistentContainer.load(modelName: modelName, url: storeURL, in: Bundle(for: CoreDataCache.self))
        self.context = persistanceStoreContainer.newBackgroundContext()
    }
    
    public func deleteCachedFeed(completion: @escaping (Error?) -> ()) {
        perform {
            do {
                try CoreDataCache.find(in: self.context).map(self.context.delete)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    public func insert(_ feedItems: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        perform {
            do {
                let cache = try CoreDataCache.createNewUniqueInstance(in: self.context)
                cache.timestamp = timestamp
                cache.feed = CoreDataFeedImage.convertToManagedImages(localImages: feedItems, in: self.context)
                try self.context.save()
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    public func retrieve(completion: @escaping RetrivalCompletion) {
        let request = NSFetchRequest<CoreDataCache>(entityName: CoreDataCache.entity().name!)
        request.returnsObjectsAsFaults = false
        
        do {
            guard let cache = try self.context.fetch(request).first else {
                completion(.empty)
                return
            }
            completion(.found(feed: cache.localFeed, timestamp: cache.timestamp))
        } catch {
            completion(.failure(error: error))
        }
        
    }
    
    private func perform(performBlock: @escaping () -> ()) {
        self.context.perform {
            performBlock()
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
