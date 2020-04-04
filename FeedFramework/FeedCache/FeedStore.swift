import Foundation

public typealias CachedFeed = (feed: [LocalFeedImage], timestamp: Date)

public protocol FeedStore {
    typealias DeletionResult = Error?
    typealias DeleteCacheCompletion = (DeletionResult) -> ()
    
    typealias InsertionResult = Error?
    typealias InsertionCompletion = (InsertionResult) -> ()
    
    typealias RetrivalCompletion = (RetrievalCachedFeedResult) -> ()
    typealias RetrievalCachedFeedResult = Result<CachedFeed?, Error>
    
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
