import Foundation

public protocol FeedStore {
    typealias DeleteCacheCompletion = (Error?) -> ()
    typealias InsertionCompletion = (Error?) -> ()
    
    func deleteCachedFeed(completion:  @escaping (Error?) -> ())
    func insert(_ feedItems: [LocalFeedItem], timestamp: Date, completion: @escaping InsertionCompletion)
}
