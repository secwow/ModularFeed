import Foundation

public enum RetrieveCachedFeedResult {
    case empty
    case found(feed: [LocalFeedImage], timestamp: Date)
    case failure(error: Error)
}

public protocol FeedStore {
    typealias DeleteCacheCompletion = (Error?) -> ()
    typealias InsertionCompletion = (Error?) -> ()
    typealias RetrivalCompletion = (RetrieveCachedFeedResult) -> ()
    // Completion can be called at any Thread
    // Client are responsible for dispatch it on correct thread
    func deleteCachedFeed(completion: @escaping (Error?) -> ())
    // Completion can be called at any Thread
    // Client are responsible for dispatch it on correct thread
    func insert(_ feedItems: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion)
    // Completion can be called at any Thread
    // Client are responsible for dispatch it on correct thread
    func retrieve(completion: @escaping RetrivalCompletion)
}
