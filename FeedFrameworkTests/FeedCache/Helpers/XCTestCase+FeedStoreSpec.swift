import XCTest
import FeedFramework

extension FeedStoreSpecs where Self: XCTestCase {
    func assertThatRetriveDeliversEmptyOnEmptyCache(on sut: FeedStore) {
        self.expect(sut, toRetrive: .empty)
    }
    
    func assertThatRetriveHasNoSideEffectsOnEmptyCache(on sut: FeedStore) {
        
        self.expect(sut, toRetrieveTwice: .empty)
    }
    
    func assertThatRetriveDeliversFoundValueOnNonEmptyCache(on sut: FeedStore) {
        let timeStamp = Date()
        let insertedFeed = uniqueImageFeed()
        
        self.insert(insertedFeed.localRepresentation, timestamp: timeStamp, to: sut)
        self.expect(sut, toRetrieveTwice: .found(feed: insertedFeed.localRepresentation, timestamp: timeStamp))
    }
    
    func assertThatInsertOverridesPreviouslyInsertedCacheValues(on sut: FeedStore) {
        insert(uniqueImageFeed().localRepresentation, timestamp: Date(), to: sut)
        let latestFeed = uniqueImageFeed().localRepresentation
        let latestTimestamp = Date()
        insert(latestFeed, timestamp: latestTimestamp, to: sut)
        
        expect(sut, toRetrieveTwice: .found(feed: latestFeed, timestamp: latestTimestamp))
    }
    
    
    func assertThatInsertDeliversNoErrorOnNonEmpryCache(on sut: FeedStore) {
        insert(uniqueImageFeed().localRepresentation, timestamp: Date(), to: sut)
        let latestInsertionError = insert(uniqueImageFeed().localRepresentation, timestamp: Date(), to: sut)
        
        XCTAssertNil(latestInsertionError)
    }
    
    func assertThatDeleteDeliversNoErrorOnEmptyCache(on sut: FeedStore) {
        let deletionError = deleteCache(from: sut)
        
        XCTAssertNil(deletionError)
    }
    
    func assertThatDeleteEmptiesPreviouslyInsertedCache(on sut: FeedStore) {
         insert(uniqueImageFeed().localRepresentation, timestamp: Date(), to: sut)
        
         let deletionError = deleteCache(from: sut)
         XCTAssertNil(deletionError)
         expect(sut, toRetrive: .empty)
    }
    
    func assertThatDeleteEmptiesPreviouslyInsertedCacheHasNoSideEffect(on sut: FeedStore) {
         insert(uniqueImageFeed().localRepresentation, timestamp: Date(), to: sut)
        
         deleteCache(from: sut)
         expect(sut, toRetrive: .empty)
    }
    
    func assertThatSideEffectRunSerially(on sut: FeedStore) {
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
}


extension FeedStoreSpecs where Self: XCTestCase {
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
        let sut = CodableFeedStore(with: storeURL ?? specificTestURL())
        trackForMemoryLeak(object: sut, file: file, line: line)
        return sut
    }
    
    func expect(_ sut: FeedStore, toRetrieveTwice result: RetrieveCachedFeedResult) {
        self.expect(sut, toRetrive: result)
        self.expect(sut, toRetrive: result)
    }
    
    func expect(_ sut: FeedStore,
                toRetrive expectedResult: RetrieveCachedFeedResult,
                file: StaticString = #file,
                line: UInt = #line) {
        let exp = XCTestExpectation()
        sut.retrieve { (recievedResult) in
            switch (recievedResult, expectedResult) {
                
            case let (.found(recievedFeed), .found(expectedFeed)):
                XCTAssertEqual(recievedFeed.feed, expectedFeed.feed, file: file, line: line)
                XCTAssertEqual(recievedFeed.timestamp, expectedFeed.timestamp, file: file, line: line)
            case (.empty, .empty), (.failure, .failure):
                break
            default:
                XCTFail(file: file, line: line)
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func cacheURL() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .systemDomainMask).first!
    }

    func deleteStore() {
        try? FileManager.default.removeItem(at: specificTestURL())
    }
    
    func specificTestURL() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
    }
}
