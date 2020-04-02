import Foundation

private class FeedCachePolicy {
    private static let calendar = Calendar(identifier: .gregorian)
    
    private init () {}
    
    private static var maxCacheAgeInDays: Int {
        return 7
    }
    
    static func validate(timestamp: Date, against date: Date) -> Bool {

        
        guard let maxCacheDate = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp) else {
            return false
        }
        
        return date < maxCacheDate
    }
}


public final class LocalFeedLoder {
    private let feedStore: FeedStore
    private let currentDate: () -> Date
    
    public init(with feedStore: FeedStore, currentDate: @escaping () -> Date) {
        self.feedStore = feedStore
        self.currentDate = currentDate
    }
}

extension LocalFeedLoder {
    public typealias SaveResult = Error?
    
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
    
    private func cache(items: [FeedImage], with completion: @escaping (SaveResult) -> ()) {
        feedStore.insert(items.toLocal(), timestamp: currentDate()) { [weak self] error in
            guard self != nil else { return }
            completion(error)
        }
    }
}

extension LocalFeedLoder: FeedLoader {
    public typealias LoadResult = LoadFeedResult
    
    public func load(completion: @escaping (LoadResult) -> ()) {
        feedStore.retrive {[weak self] (result) in
            guard let self = self else { return }
            
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case let .found(feed, timestamp) where FeedCachePolicy.validate(timestamp: timestamp, against: self.currentDate()):
                completion(.success(feed.toModels()))
            case .found, .empty:
                completion(.success([]))
            }
        }
    }
}

extension LocalFeedLoder {
    public func validateCache() {
        feedStore.retrive {[weak self] (result) in
            guard let self = self else { return }
            switch result {
            case .failure(_):
                self.feedStore.deleteCachedFeed { (_) in
                }
            case let .found(_, timestamp) where !FeedCachePolicy.validate(timestamp: timestamp, against: self.currentDate()):
                self.feedStore.deleteCachedFeed { (_) in
                }
                break
            case .found, .empty:
                break
            }
        }
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
