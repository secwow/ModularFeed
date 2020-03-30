import Foundation

public protocol FeedStore {
    typealias DeleteCacheCompletion = (Error?) -> ()
    typealias InsertionCompletion = (Error?) -> ()
    typealias RetrivalCompletion = (Error?) -> ()
    
    func deleteCachedFeed(completion: @escaping (Error?) -> ())
    func insert(_ feedItems: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion)
    func retrive(completion: RetrivalCompletion)
}
