import FeedFramework
import XCTest
import CoreData

class CoreDataFeedStore: FeedStore {
    func deleteCachedFeed(completion: @escaping (Error?) -> ()) {
        
    }
    
    func insert(_ feedItems: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        
    }
    
    func retrieve(completion: @escaping RetrivalCompletion) {
        completion(.empty)
    }
}

//extension NSManagedObjectContext {
//
//}

class CoreDataFeedStoreTests: XCTestCase, FailableCompostion {
    func test_retrive_deliversEmptyOnEmptyCache() {
        let sut = CoreDataFeedStore()
        
        assertThatRetriveDeliversEmptyOnEmptyCache(on: sut)
    }
    
    func test_retrive_deliversFailureOnRetrievalError() {
        
    }
    
    func test_retrive_deliversFailureHasNoSideEffectsOnError() {
        
    }
    
    func test_retrive_hasNoSideEffectsOnEmptyCache() {
        
    }
    
    func test_retrive_deliversFoundValueOnNonEmptyCache() {
        
    }
    
    func test_delete_deliversErrorOnDeletionError() {
        
    }
    
    func test_delete_OnEmptyCacheDeliversNoError() {
        
    }
    
    func test_insert_deliversErrorOnInsertionError() {
        
    }
    
    func test_insert_hasNoSideEffectsOnInsertionError() {
        
    }
    
    func test_insert_overridesPreviouslyInsertedDataWithNewDeliversNoError() {
        
    }
    
    func test_insert_overridesPreviouslyInsertedCacheValues() {
        
    }
    
    func test_delete_hasNoSideEffectOnEmptyCache() {
        
    }
    
    func test_delete_emptiesPreviouslyInsertedCache() {
        
    }
    
    func test_storeSideEffects_runSerially() {
        
    }
    
    func makeSUT(storeURL: URL? = nil, file: StaticString = #file, line: UInt = #line) -> FeedStore {
        let sut = CoreDataFeedStore()
        trackForMemoryLeak(object: sut )
        return sut
    }
}
