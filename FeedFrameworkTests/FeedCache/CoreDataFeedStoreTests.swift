import FeedFramework
import XCTest
import CoreData

class CoreDataFeedStoreTests: XCTestCase, FeedStoreSpecs {
    
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
    
    func test_delete_OnEmptyCacheDeliversNoError() {
        let sut = makeSUT()
        
        assertThatDeleteDeliversNoErrorOnEmptyCache(on: sut)
    }
    
    func test_insert_overridesPreviouslyInsertedCacheValues() {
        let sut = makeSUT()
        
        assertThatInsertOverridesPreviouslyInsertedCacheValues(on: sut)
    }
    
    func test_delete_hasNoSideEffectOnEmptyCache() {
        let sut = makeSUT()
        
        assertThatDeleteEmptiesPreviouslyInsertedCacheHasNoSideEffect(on: sut)
    }
    
    func test_delete_emptiesPreviouslyInsertedCache() {
        let sut = makeSUT()
        
        assertThatDeleteEmptiesPreviouslyInsertedCache(on: sut)
    }
    
    func test_storeSideEffects_runSerially() {
        let sut = makeSUT()
        
        assertThatSideEffectRunSerially(on: sut)
    }
    
    func makeSUT(storeURL: URL = URL(fileURLWithPath: "/dev/null"), file: StaticString = #file, line: UInt = #line) -> FeedStore {
        let sut = try! CoreDataFeedStore(with: storeURL, bundle: Bundle(for: CoreDataFeedStore.self))
        trackForMemoryLeak(object: sut)
        return sut
    }
}
