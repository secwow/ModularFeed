import Foundation
import FeedFramework

class FeedStoreSpy: FeedStore {
 
    private var deletionCompletions: [DeleteCacheCompletion] = []
    private var insertionCompletions: [InsertionCompletion] = []
    private var retrivalCompletions: [RetrivalCompletion] = []
    private(set) var recievedMessages: [RecivedMessage] = []
    
    enum RecivedMessage: Equatable {
        case deleteCacheFeedMessage
        case insert([LocalFeedImage], Date)
        case retrive
    }
    
    func deleteCachedFeed(completion: @escaping (DeletionResult) -> ()) {
        deletionCompletions.append(completion)
        recievedMessages.append(.deleteCacheFeedMessage)
    }
    
    func insert(_ feedItems: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        insertionCompletions.append(completion)
        recievedMessages.append(.insert(feedItems, timestamp))
    }
    
    func retrieve(completion: @escaping RetrivalCompletion) {
        self.retrivalCompletions.append(completion)
        recievedMessages.append(.retrive)
    }
    
    func completeDeletion(with error: Error, at index: Int = 0) {
        deletionCompletions[index](.failure(error))
    }
    
    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](.success(()))
    }
    
    func completeInsertion(with error: Error, at index: Int = 0) {
        insertionCompletions[index](.failure(error))
    }
    
    func completeInsertionSuccessfully(at index: Int = 0) {
        insertionCompletions[index](.success(()))
    }
    
    func completeRetrival(with error: Error, at index: Int = 0) {
        retrivalCompletions[index](.failure(error))
    }
    
    func completeWithEmptyCache(at index: Int = 0) {
        retrivalCompletions[index](.success(.none))
    }
    
    func completeRetrival(with feed: [LocalFeedImage], timestamp: Date, at index: Int = 0) {
        retrivalCompletions[index](.success(CachedFeed(feed: feed, timestamp: timestamp)))
    }
}
