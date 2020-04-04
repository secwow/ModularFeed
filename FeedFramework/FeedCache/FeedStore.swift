import Foundation

public enum CachedFeed {
    case empty
    case found(feed: [LocalFeedImage], timestamp: Date)
}


public protocol FeedStore {
    typealias DeleteCacheCompletion = (Error?) -> ()
    typealias InsertionCompletion = (Error?) -> ()
    typealias RetrivalCompletion = (RetrievalCachedFeedResult) -> ()
    typealias RetrievalCachedFeedResult = Result<CachedFeed, Error>
    /// Completion can be called at any Thread
    /// Client are responsible for dispatch it on correct thread
    func deleteCachedFeed(completion: @escaping (Error?) -> ())
    /// Completion can be called at any Thread
    /// Client are responsible for dispatch it on correct thread
    func insert(_ feedItems: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion)
    /// Completion can be called at any Thread
    /// Client are responsible for dispatch it on correct thread
    func retrieve(completion: @escaping RetrivalCompletion)
}
