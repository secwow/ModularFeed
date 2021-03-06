import Foundation

public final class LocalFeedLoder {
    private let feedStore: FeedStore
    private let currentDate: () -> Date
    
    public init(with feedStore: FeedStore, currentDate: @escaping () -> Date) {
        self.feedStore = feedStore
        self.currentDate = currentDate
    }
}

extension LocalFeedLoder {
    public typealias SaveResult = Result<Void, Error>
    
    public func save(items: [FeedImage], completion: @escaping (SaveResult) -> () = { _ in }) {
        feedStore.deleteCachedFeed { [weak self] deletionResultError in
            guard let self = self else { return }
            
            switch deletionResultError {
            case .success:
                 self.cache(items: items, with: completion)
            case let .failure(error):
                 completion(.failure(error))
            }
        }
    }
    
    private func cache(items: [FeedImage], with completion: @escaping (SaveResult) -> ()) {
        feedStore.insert(items.toLocal(), timestamp: currentDate()) { [weak self] insertionResultError in
            guard self != nil else { return }
            completion(insertionResultError)
        }
    }
}

extension LocalFeedLoder: FeedLoader {
    public typealias LoadResult = FeedLoader.Result
    
    public func load(completion: @escaping (LoadResult) -> ()) {
        feedStore.retrieve { [weak self] (result) in
            guard let self = self else { return }
            
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case let .success(.some(cache)) where FeedCachePolicy.validate(timestamp: cache.timestamp, against: self.currentDate()):
                completion(.success(cache.feed.toModels()))
            case .success(.some), .success(.none):
                completion(.success([]))
            }
        }
    }
}

extension LocalFeedLoder {
    public func validateCache() {
        feedStore.retrieve { [weak self] (result) in
            guard let self = self else { return }
            switch result {
            case .failure(_):
                self.feedStore.deleteCachedFeed { (_) in
                }
            case let .success(.some(cache)) where !FeedCachePolicy.validate(timestamp: cache.timestamp, against: self.currentDate()):
                self.feedStore.deleteCachedFeed { (_) in
                }
                break
            case .success(.some), .success(.none):
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
