import Foundation
import FeedFramework

class FeedStoreSpy: FeedStore {
    typealias DeleteCacheCompletion = (Error?) -> ()
    typealias InsertionCompletion = (Error?) -> ()
    typealias RetrivalCompletion = (Error?) -> ()
    private var deletionCompletions: [DeleteCacheCompletion] = []
    private var insertionCompletions: [InsertionCompletion] = []
    private var retrivalCompletions: [RetrivalCompletion] = []
    private(set) var recievedMessages: [RecivedMessage] = []
    
    enum RecivedMessage: Equatable {
        case deleteCacheFeedMessage
        case insert([LocalFeedImage], Date)
        case retrive
    }
    
    func deleteCachedFeed(completion: @escaping (Error?) -> ()) {
        deletionCompletions.append(completion)
        recievedMessages.append(.deleteCacheFeedMessage)
    }
    
    func insert(_ feedItems: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        insertionCompletions.append(completion)
        recievedMessages.append(.insert(feedItems, timestamp))
    }
    
    func retrive(completion: @escaping (Error?) -> ()) {
        self.retrivalCompletions.append(completion)
        recievedMessages.append(.retrive)
    }
    
    func completeDeletion(with error: Error, at index: Int = 0) {
        deletionCompletions[index](error)
    }
    
    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
    }
    
    func completeInsertion(with error: Error, at index: Int = 0) {
        insertionCompletions[index](error)
    }
    
    func completeInsertionSuccessfully(at index: Int = 0) {
        insertionCompletions[index](nil)
    }
    
    func completeRetrival(with error: Error, at index: Int = 0) {
        retrivalCompletions[index](error)
    }
}
