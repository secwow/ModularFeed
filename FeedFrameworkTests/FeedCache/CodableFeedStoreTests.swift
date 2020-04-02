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
        
        self.expect(sut, toRetrive: .empty)
    }
    
    func test_retrive_hasNoSideEffectsONEmptyCacheTwice() {
        let sut = makeSUT()
        
        self.expect(sut, toRetrieveTwice: .empty)
    }
    
    func test_retrive_deliversInsertedValue() {
        let sut = makeSUT()
        let timeStamp = Date()
        let insertedFeed = uniqueImageFeed()
        
        self.insert(insertedFeed.localRepresentation, timestamp: timeStamp, to: sut)
        self.expect(sut, toRetrive: .found(feed: insertedFeed.localRepresentation, timestamp: timeStamp))
    }
    
    func test_retrive_deliversFoundValueOnNonEmptyCache() {
        let sut = makeSUT()
        let timeStamp = Date()
        let insertedFeed = uniqueImageFeed()
        
        self.insert(insertedFeed.localRepresentation, timestamp: timeStamp, to: sut)
        self.expect(sut, toRetrieveTwice: .found(feed: insertedFeed.localRepresentation, timestamp: timeStamp))
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
    
    func test_insert_overridesPreviouslyInsertedDataWithNew() {
        let sut = makeSUT()
        
        insert(uniqueImageFeed().localRepresentation, timestamp: Date(), to: sut)
        let latestFeed = uniqueImageFeed().localRepresentation
        let latestTimestamp = Date()
        insert(latestFeed, timestamp: latestTimestamp, to: sut)
        
        expect(sut, toRetrieveTwice: .found(feed: latestFeed, timestamp: latestTimestamp))
    }
    
    func test_insert_overridesPreviouslyInsertedDataWithNewDeliversNoError() {
        let sut = makeSUT()
        
        insert(uniqueImageFeed().localRepresentation, timestamp: Date(), to: sut)
        let latestFeed = uniqueImageFeed().localRepresentation
        let latestTimestamp = Date()
        let latestInsertionError = insert(latestFeed, timestamp: latestTimestamp, to: sut)
        
        XCTAssertNil(latestInsertionError)
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
          let deletionError = deleteCache(from: sut)
          
          XCTAssertNil(deletionError)
      }
    
    func test_delete_deletePreviouslyInsertedCache() {
        let sut = makeSUT()
        insert(uniqueImageFeed().localRepresentation, timestamp: Date(), to: sut)
       
        let deletionError = deleteCache(from: sut)
        XCTAssertNil(deletionError)
        expect(sut, toRetrive: .empty)
    }
    
    func test_delete_deliversErrorOnDeletionError() {
        let noDeletePermissionURL = cacheURL()
        let sut = makeSUT(storeURL: noDeletePermissionURL)
        insert(uniqueImageFeed().localRepresentation, timestamp: Date(), to: sut)
        assertThatDeleteDeliversErrorOnDeletionError(on: sut)
    }
    
    
    func test_storeSideEffects_runSerially() {
        let sut = makeSUT()
        var completedOperationInOrder = [XCTestExpectation]()
        
        let op1 = expectation(description: "Operation 1")
        
        sut.insert(uniqueImageFeed().localRepresentation, timestamp: Date()) { (error) in
            completedOperationInOrder.append(op1)
            op1.fulfill()
        }
        
        let op2 = expectation(description: "Operation 1")
        sut.deleteCachedFeed(completion: { (error) in
            completedOperationInOrder.append(op2)
            op2.fulfill()
        })
        
        let op3 = expectation(description: "Operation 1")
        sut.insert(uniqueImageFeed().localRepresentation, timestamp: Date()) { (error) in
            completedOperationInOrder.append(op3)
            op3.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
        
        XCTAssertEqual([op1, op2, op3], completedOperationInOrder)
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
    
    private func deleteStore() {
        try? FileManager.default.removeItem(at: testSpecificURL())
    }
    
    private func testSpecificURL() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
    }
}

