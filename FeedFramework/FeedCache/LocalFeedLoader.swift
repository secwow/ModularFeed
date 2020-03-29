import Foundation

public final class LocalFeedLoder {
    
    public typealias SaveResult = Error?
    let feedStore: FeedStore
    let currentDate: () -> Date
    
    public init(with feedStore: FeedStore, currentDate: @escaping () -> Date) {
        self.feedStore = feedStore
        self.currentDate = currentDate
    }
    
    public func save(items: [FeedItem], completion: @escaping (SaveResult) -> () = { _ in }) {
        feedStore.deleteCachedFeed { [weak self] error in
            guard let self = self else { return }
            if let cacheDeletionError = error {
                completion(cacheDeletionError)
            } else {
                self.cache(items: items, with: completion)
            }
        }
    }
    
    private func cache(items: [FeedItem], with completion: @escaping (SaveResult) -> ()) {
        feedStore.insert(items, timestamp: currentDate()) { [weak self] error in
            guard self != nil else { return }
            completion(error)
        }
    }
}
