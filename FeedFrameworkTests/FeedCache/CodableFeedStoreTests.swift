import FeedFramework
import XCTest

class CodableFeedStoreTests: XCTestCase, FailableCompostion {
    override func setUp() {
        super.tearDown()
        self.setupEmptyStore()
    }
    
    override func tearDown() {
        super.tearDown()
        self.undoStoreSideEffects()
    }
    
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
    
    func test_retrive_deliversFailureOnRetrievalError() {
        let storeURL = testSpecificURL()
        let sut = makeSUT(storeURL: storeURL)
        
        try! "Invalid data".write(to: storeURL, atomically: true, encoding: .utf8)
        assertThatRetrieveDeliversFailureOnRetrievalError(on: sut)
    }
    
    func test_retrive_deliversFailureHasNoSideEffectsOnError() {
        let storeURL = testSpecificURL()
        let sut = makeSUT(storeURL: storeURL)
        
        try! "Invalid data".write(to: storeURL, atomically: true, encoding: .utf8)
        assertThatRetrieveHasNoSideEffectsOnFailure(on: sut)
    }
    
    func test_insert_overridesPreviouslyInsertedCacheValues() {
        let sut = makeSUT()
        
        assertThatInsertOverridesPreviouslyInsertedCacheValues(on: sut)
    }
    
    func test_insert_overridesPreviouslyInsertedDataWithNewDeliversNoError() {
        let sut = makeSUT()
        
        assertThatInsertDeliversNoErrorOnNonEmpryCache(on: sut)
    }
    
    func test_insert_deliversErrorOnInsertionError() {
        let invalidURL = URL(string: "invalid://store")
        let sut = makeSUT(storeURL: invalidURL)
        
        assertThatInsertDeliversErrorOnInsertionError(on: sut)
    }
    
    func test_insert_hasNoSideEffectsOnInsertionError() {
        let invalidURL = URL(string: "invalid://store")
        let sut = makeSUT(storeURL: invalidURL)
        
        assertThatInsertHasNoSideEffectsOnInsertionError(on: sut)
    }
    
    func test_delete_hasNoSideEffectOnEmptyCache() {
        let sut = makeSUT()
        
        assertThatDeleteHasNoSideEffectsOnDeletionError(on: sut)
    }
    
    func test_delete_OnEmptyCacheDeliversNoError() {
        let sut = makeSUT()
        assertThatDeleteDeliversNoErrorOnEmptyCache(on: sut)
    }
    
    func test_delete_emptiesPreviouslyInsertedCache() {
        let sut = makeSUT()
        assertThatDeleteEmptiesPreviouslyInsertedCache(on: sut)
    }
    
    func test_delete_deletePreviouslyInsertedCacheHasNoSide() {
        let sut = makeSUT()
        assertThatDeleteEmptiesPreviouslyInsertedCacheHasNoSideEffect(on: sut)
    }
    
    func test_delete_deliversErrorOnDeletionError() {
        let noDeletePermissionURL = cacheURL()
        let sut = makeSUT(storeURL: noDeletePermissionURL)
        assertThatDeleteDeliversErrorOnDeletionError(on: sut)
    }
    
    func test_storeSideEffects_runSerially() {
        let sut = makeSUT()
        self.assertThatSideEffectRunSerially(on: sut)
    }
    
    func makeSUT(storeURL: URL? = nil, file: StaticString = #file, line: UInt = #line) -> FeedStore {
        let sut = CodableFeedStore(with: storeURL ?? testSpecificURL())
        trackForMemoryLeak(object: sut, file: file, line: line)
        return sut
    }
    
    private func setupEmptyStore() {
        self.deleteStore()
    }
    
    private func undoStoreSideEffects() {
        self.deleteStore()
    }
}

