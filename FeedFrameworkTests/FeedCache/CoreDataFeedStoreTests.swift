import FeedFramework
import XCTest
import CoreData

class CoreDataFeedStoreTests: XCTestCase, FailableInsertFeedStoreSpecs, FailableDeleteFeedStoreSpecs {
    
    func test_retrive_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()
        
        assertThatRetriveDeliversEmptyOnEmptyCache(on: sut)
    }
    
    func test_retrive_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
                
        assertThatRetriveHasNoSideEffectsOnEmptyCache(on: sut)
    }
    
    func test_retrive_deliversFoundValueOnNonEmptyCache() {
        let sut = makeSUT()
                
        assertThatRetriveDeliversFoundValueOnNonEmptyCache(on: sut)
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
    
    func makeSUT(storeURL: URL = URL(fileURLWithPath: "/dev/null"), file: StaticString = #file, line: UInt = #line) -> FeedStore {
        let sut = try! CoreDataFeedStore(with: storeURL, modelName: "FeedModel", bundle: Bundle(for: CoreDataFeedStore.self))
//        trackForMemoryLeak(object: sut )
        return sut
    }
}
