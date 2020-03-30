import Foundation

public final class LocalFeedLoder {
    
    public typealias SaveResult = Error?
    let feedStore: FeedStore
    let currentDate: () -> Date
    
    public init(with feedStore: FeedStore, currentDate: @escaping () -> Date) {
        self.feedStore = feedStore
        self.currentDate = currentDate
    }
    
    public func load(completion: @escaping (Error?) -> ()) {
        feedStore.retrive(completion: completion)
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
    
    private func cache(items: [FeedImage], with completion: @escaping (SaveResult) -> ()) {
        feedStore.insert(items.toLocal(), timestamp: currentDate()) { [weak self] error in
            guard self != nil else { return }
            completion(error)
        }
    }
}

private extension Array where Element == FeedImage {
    func toLocal() -> [LocalFeedImage] {
        return map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)}
    }
}
