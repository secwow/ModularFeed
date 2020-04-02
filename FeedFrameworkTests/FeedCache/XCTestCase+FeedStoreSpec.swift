import XCTest
import FeedFramework

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
        let sut = CodableFeedStore(with: storeURL ?? testSpecificURL())
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
        try? FileManager.default.removeItem(at: testSpecificURL())
    }
    
    func testSpecificURL() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
    }
}
