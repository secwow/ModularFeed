import XCTest
import FeedFramework

extension FeedStoreSpecs where Self: XCTestCase {
    func assertThatRetriveDeliversEmptyOnEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        self.expect(sut, toRetrive: .success(.none), file: file, line: line)
    }
    
    func assertThatRetriveHasNoSideEffectsOnEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        self.expect(sut, toRetrieveTwice: .success(.none), file: file, line: line)
    }
    
    func assertThatRetriveDeliversFoundValueOnNonEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        let timeStamp = Date()
        let insertedFeed = uniqueImageFeed()
        
        self.insert(insertedFeed.localRepresentation, timestamp: timeStamp, to: sut)
        self.expect(sut, toRetrieveTwice: .success(CachedFeed(feed: insertedFeed.localRepresentation, timestamp: timeStamp)), file: file, line: line)
    }
    
    func assertThatInsertOverridesPreviouslyInsertedCacheValues(on sut: FeedStore , file: StaticString = #file, line: UInt = #line) {
        insert(uniqueImageFeed().localRepresentation, timestamp: Date(), to: sut)
        let latestFeed = uniqueImageFeed().localRepresentation
        let latestTimestamp = Date()
        insert(latestFeed, timestamp: latestTimestamp, to: sut)
        
        expect(sut, toRetrieveTwice: .success(CachedFeed(feed: latestFeed, timestamp: latestTimestamp)), file: file, line: line)
    }
    
    
    func assertThatInsertDeliversNoErrorOnNonEmpryCache(on sut: FeedStore) {
        insert(uniqueImageFeed().localRepresentation, timestamp: Date(), to: sut)
        let latestInsertionError = insert(uniqueImageFeed().localRepresentation, timestamp: Date(), to: sut)
        
        XCTAssertNil(latestInsertionError)
    }
    
    func assertThatDeleteDeliversNoErrorOnEmptyCache(on sut: FeedStore) {
        let deletionResult = deleteCache(from: sut)
        
        XCTAssertNil(deletionResult)
    }
    
    func assertThatDeleteEmptiesPreviouslyInsertedCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
         insert(uniqueImageFeed().localRepresentation, timestamp: Date(), to: sut)
        
         let deletionError = deleteCache(from: sut)
         XCTAssertNil(deletionError)
         expect(sut, toRetrive: .success(.none), file: file, line: line)
    }
    
    func assertThatDeleteEmptiesPreviouslyInsertedCacheHasNoSideEffect(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
         insert(uniqueImageFeed().localRepresentation, timestamp: Date(), to: sut)
        
         deleteCache(from: sut)
         expect(sut, toRetrive: .success(.none), file: file, line: line)
    }
    
    func assertThatSideEffectRunSerially(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
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
        
        XCTAssertEqual([op1, op2, op3], completedOperationInOrder, file: file, line: line)
    }
}


extension FeedStoreSpecs where Self: XCTestCase {
    @discardableResult
    func insert(_ feed: [LocalFeedImage], timestamp: Date, to sut: FeedStore, file: StaticString = #file, line: UInt = #line) -> Error? {
        let exp = XCTestExpectation(description: "Wait to insert")
        
        var capturedError: Error?
        sut.insert(feed, timestamp: timestamp) { insertionResult in
            if case let Result.failure(error) = insertionResult { capturedError = error }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 3.0)
        
        return capturedError
    }
    
    @discardableResult
    func deleteCache(from sut: FeedStore) -> Error? {
        let exp = XCTestExpectation(description: "Wait to insert")
        
        var capturedError: Error?
        sut.deleteCachedFeed { (deletionResult) in
            if case let Result.failure(error) = deletionResult { capturedError = error }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 3.0)
        
        return capturedError
    }
    
    func makeSUT(storeURL: URL? = nil, file: StaticString = #file, line: UInt = #line) -> FeedStore {
        let sut = CodableFeedStore(with: storeURL ?? specificTestURL())
        trackForMemoryLeak(object: sut, file: file, line: line)
        return sut
    }
    
    func expect(_ sut: FeedStore, toRetrieveTwice result: FeedStore.RetrievalCachedFeedResult, file: StaticString = #file, line: UInt = #line) {
        self.expect(sut, toRetrive: result, file: file, line: line)
        self.expect(sut, toRetrive: result, file: file, line: line)
    }
    
    func expect(_ sut: FeedStore,
                toRetrive expectedResult: FeedStore.RetrievalCachedFeedResult,
                file: StaticString = #file,
                line: UInt = #line) {
        let exp = XCTestExpectation(description: "Waiting for retriving result")
        sut.retrieve { (recievedResult) in
            switch (recievedResult, expectedResult) {
            case (.success(.none), .success(.none)), (.failure, .failure):
               break
            case let (.success(.some(recievedFeed)), .success(.some(expectedFeed))):
                XCTAssertEqual(recievedFeed.feed, expectedFeed.feed, file: file, line: line)
                XCTAssertEqual(recievedFeed.timestamp, expectedFeed.timestamp, file: file, line: line)
            default:
                XCTFail("Failed: expected \(expectedResult) but got \(recievedResult) instead", file: file, line: line)
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
