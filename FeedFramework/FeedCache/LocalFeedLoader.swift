import Foundation

public final class LocalFeedLoder {
    
    public typealias SaveResult = Error?
    public typealias LoadResult = LoadFeedResult
    let feedStore: FeedStore
    let currentDate: () -> Date
    
    public init(with feedStore: FeedStore, currentDate: @escaping () -> Date) {
        self.feedStore = feedStore
        self.currentDate = currentDate
    }
    
    public func load(completion: @escaping (LoadResult) -> ()) {
        feedStore.retrive {[weak self] (result) in
            guard let self = self else { return }
            
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case let .found(feed, timestamp) where self.validate(date: timestamp):
                completion(.success(feed.toModels()))
            case .found:
                completion(.success([]))
            case .empty:
                completion(.success([]))
            }
        }
    }
    
    public func save(items: [FeedImage], completion: @escaping (SaveResult) -> () = { _ in }) {
        feedStore.deleteCachedFeed { [weak self] error in
            guard let self = self else { return }
            if let cacheDeletionError = error {
                completion(cacheDeletionError)
            } else {
                self.cache(items: items, with: completion)
            }
        }
    }
    
    public func validateCache(completion: @escaping () -> () = {}) {
        feedStore.retrive {[unowned self] (result) in
            switch result {
            case .empty:
                break
            case .failure(_):
                self.feedStore.deleteCachedFeed { (_) in
                }
            case let .found(_, timestamp) where !self.validate(date: timestamp):
                self.feedStore.deleteCachedFeed { (_) in
                }
                break
            case .found, .empty:
                break
            }
            
            completion()
        }
        
        
    }
    
    private func cache(items: [FeedImage], with completion: @escaping (SaveResult) -> ()) {
        feedStore.insert(items.toLocal(), timestamp: currentDate()) { [weak self] error in
            guard self != nil else { return }
            completion(error)
        }
    }
    
    private var maxCacheAgeInDays: Int {
        return 7
    }
    
    private func validate(date: Date) -> Bool {
        let calendar = Calendar(identifier: .gregorian)
        
        guard let maxCacheDate = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: date) else {
            return false
        }
        
        return currentDate() < maxCacheDate
    }
}

private extension Array where Element == FeedImage {
    func toLocal() -> [LocalFeedImage] {
        return map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)}
    }
}

private extension Array where Element == LocalFeedImage {
    func toModels() -> [FeedImage] {
        return map { FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)}
    }
}
