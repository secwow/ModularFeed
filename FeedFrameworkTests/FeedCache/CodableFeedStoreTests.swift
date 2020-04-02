import FeedFramework
import XCTest

//Insert
//    - [V] To empty cache works
//    - [V] To non-empty cache overrides previous value
//    - [V] Error (if possible to simulate, e.g., no write permission)
//
//- Retrieve
//    - [V]Empty cache works (before something is inserted)
//    - [V]Non-empty cache returns data
//    - [V]Non-empty cache twice returns same data (retrieve should have no side-effects)
//    - [V]Error (if possible to simulate, e.g., invalid data)
//
//- Delete
//    - [V]Empty cache does nothing (cache stays empty and does not fail)
//    - [V]Inserted data leaves cache empty
//    - [V]Error (if possible to simulate, e.g., no write permission)
//
//- Side-effects must run serially to avoid race-conditions (deleting the wrong cache... overriding the latest data...)

class CodableFeedStoreTests: XCTestCase {
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
    
    func test_retriveAfterInsertingToEmptyCache_deliversInsertedValue() {
        let sut = makeSUT()
        let timeStamp = Date()
        let insertedFeed = uniqueImageFeed()
        
        self.insert(insertedFeed.localRepresentation, timestamp: timeStamp, to: sut)
        self.expect(sut, toRetrive: .found(feed: insertedFeed.localRepresentation, timestamp: timeStamp))
    }
    
    func test_insert_deliversFoundValueOnNonEmptyCache() {
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
        expect(sut, toRetrive: .failure(error: anyNSError()))
    }
    
    func test_retrive_deliversFailureHasNoSideEffectsOnError() {
        let storeURL = testSpecificURL()
        let sut = makeSUT(storeURL: storeURL)
        
        try! "Invalid data".write(to: storeURL, atomically: true, encoding: .utf8)
        expect(sut, toRetrieveTwice: .failure(error: anyNSError()))
    }
    
    func test_insert_overridesPreviouslyInsertedDataWithNew() {
        let sut = makeSUT()
        
        let firstInsertionError = insert(uniqueImageFeed().localRepresentation, timestamp: Date(), to: sut)
        XCTAssertNil(firstInsertionError)
        let latestFeed = uniqueImageFeed().localRepresentation
        let latestTimestamp = Date()
        let latestInsertionError = insert(latestFeed, timestamp: latestTimestamp, to: sut)
        
        XCTAssertNil(latestInsertionError)
        expect(sut, toRetrieveTwice: .found(feed: latestFeed, timestamp: latestTimestamp))
    }
    
    func test_insert_deliversErrorOnInsertionError() {
        let invalidURL = URL(string: "invalid://store")
        let sut = makeSUT(storeURL: invalidURL)
        
        let latestInsertionError = insert(uniqueImageFeed().localRepresentation, timestamp: Date(), to: sut)
        
        XCTAssertNotNil(latestInsertionError)
    }
    
    func test_retrive_deliversErrorOnInsertionError() {
        let invalidURL = URL(string: "invalid://store")
        let sut = makeSUT(storeURL: invalidURL)
        
        let latestInsertionError = insert(uniqueImageFeed().localRepresentation, timestamp: Date(), to: sut)
        
        XCTAssertNotNil(latestInsertionError)
    }
    
    func test_delete_doesNotDeliversErrorUponCacheEmpty() {
        let sut = makeSUT()
        
        let deletionError = deleteCache(from: sut)
        
        XCTAssertNil(deletionError)
        expect(sut, toRetrive: .empty)
    }
    
    func test_delete_hasNoSideEffectOnEmptyCache() {
        let sut = makeSUT()
        
        let deletionError = deleteCache(from: sut)
        
        XCTAssertNil(deletionError)
        expect(sut, toRetrieveTwice: .empty)
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
        
        let deletionError = deleteCache(from: sut)
        XCTAssertNotNil(deletionError)
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
    
    func cacheURL() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .systemDomainMask).first!
    }
    
    @discardableResult
    func insert(_ feed: [LocalFeedImage], timestamp: Date, to sut: FeedStore, file: StaticString = #file, line: UInt = #line) -> Error? {
        let exp = XCTestExpectation(description: "Wait to insert")
        var capturedError: Error?
        sut.insert(feed, timestamp: timestamp) { insertionError in
            capturedError = insertionError
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        
        return capturedError
    }
    
    @discardableResult
    func deleteCache(from sut: FeedStore) -> Error? {
        let exp = XCTestExpectation(description: "Wait to insert")
        
        var capturedError: Error?
        sut.deleteCachedFeed { (error) in
            capturedError = error
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        
        return capturedError
    }
    
    func makeSUT(storeURL: URL? = nil, file: StaticString = #file, line: UInt = #line) -> FeedStore {
        let sut = CodableFeedStore(with: storeURL ?? testSpecificURL())
        trackForMemoryLeak(object: sut, file: file, line: line)
        return sut
    }
    
    private func expect(_ sut: FeedStore, toRetrieveTwice result: RetrieveCachedFeedResult) {
        self.expect(sut, toRetrive: result)
        self.expect(sut, toRetrive: result)
    }
    
    private func expect(_ sut: FeedStore,
                        toRetrive expectedResult: RetrieveCachedFeedResult,
                        file: StaticString = #file,
                        line: UInt = #line) {
        let exp = XCTestExpectation()
        sut.retrieve { (recievedResult) in
            switch (recievedResult, expectedResult) {
                
            case let (.found(recievedFeed), .found(expectedFeed)):
                XCTAssertEqual(recievedFeed.feed, expectedFeed.feed, file: file, line: line)
                XCTAssertEqual(recievedFeed.timestamp, expectedFeed.timestamp, file: file, line: line)
                //            case let (.failure(recievedError), .failure(expectedError)):
            //                XCTAssertEqual(recievedError as NSError?, expectedError as NSError?, file: file, line: line)
            case (.empty, .empty), (.failure, .failure):
                break
            default:
                XCTFail(file: file, line: line)
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
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

