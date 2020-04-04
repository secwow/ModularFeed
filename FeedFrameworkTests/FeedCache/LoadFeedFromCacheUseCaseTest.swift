import FeedFramework
import XCTest

class LoadFeedFromCacheUseCaseTest: XCTestCase {
    func test_init_doesnNotMessageDeleteUponCreation() {
        let (store, _) = makeSUT()
        
        XCTAssertEqual(store.recievedMessages, [])
    }
    
    func test_load_requestsCacheRetrival() {
        let (store, sut) = makeSUT()
        sut.load() { _ in }
        
        XCTAssertEqual(store.recievedMessages, [.retrive])
    }
    
    func test_load_failsOnRetrivalError() {
        let (store, sut) = makeSUT()
        
        let retrivalError = anyNSError()
        
        self.expect(sut, toCompleteWithResult: .failure(retrivalError), when: {
            store.completeRetrival(with: retrivalError)
        })
    }
    
    func test_load_deliversNoErrorOnEmptyCache() {
        let (store, sut) = makeSUT()
        
        self.expect(sut, toCompleteWithResult: .success([]), when: {
            store.completeWithEmptyCache()
        })
    }
    
    func test_load_hasNoSideEffectOnCachedImagesOnNonExpiredCache() {
        let feed  = uniqueImageFeed()
        let fixedCurrentDate = Date()
        
        let (store, sut) = makeSUT(currentDate: { fixedCurrentDate })
        let lessThatSevenDaysOldTimestamp = fixedCurrentDate
            .minusFeedCacheMaxAge()
            .adding(seconds: 1)
        
        self.expect(sut, toCompleteWithResult: .success(feed.models), when: {
            store.completeRetrival(with: feed.localRepresentation, timestamp: lessThatSevenDaysOldTimestamp)
        })
    }
    
    func test_load_deliversNoCachedImagesOnSevenDaysOldCache() {
        let feed  = uniqueImageFeed()
        let fixedCurrentDate = Date()
        
        let (store, sut) = makeSUT(currentDate: { fixedCurrentDate })
        let experationTimeStamp = fixedCurrentDate
            .minusFeedCacheMaxAge()
        
        self.expect(sut, toCompleteWithResult: .success([]), when: {
            store.completeRetrival(with: feed.localRepresentation, timestamp: experationTimeStamp)
        })
    }
    
    func test_load_deliversNoCachedImagesOnMoreThanSevenDaysOldCache() {
        let feed  = uniqueImageFeed()
        let fixedCurrentDate = Date()
        
        let (store, sut) = makeSUT(currentDate: { fixedCurrentDate })
        let experationTimeStamp = fixedCurrentDate
            .minusFeedCacheMaxAge()
            .adding(seconds: -1)
        
        self.expect(sut, toCompleteWithResult: .success([]), when: {
            store.completeRetrival(with: feed.localRepresentation, timestamp: experationTimeStamp)
        })
    }
    
    func test_load_deliversErrorHasNoSideEffects() {
        let (store, sut) = makeSUT()
        sut.load { (_) in
        }
        
        store.completeRetrival(with: anyNSError())
        XCTAssertEqual(store.recievedMessages, [.retrive])
    }
    
    func test_load_hasNoSideEffectsOnCache() {
        let (store, sut) = makeSUT()
        sut.load { (_) in
            
        }
        
        store.completeWithEmptyCache()
        XCTAssertEqual(store.recievedMessages, [.retrive])
    }
    
    func test_load_doesNotDeleteCacheOnNonExpiredCache() {
        let feed  = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let (store, sut) = makeSUT(currentDate: { fixedCurrentDate })
        let experationTimeStamp = fixedCurrentDate
            .minusFeedCacheMaxAge()
            .adding(seconds: 1)
        sut.load { (_) in
            
        }
        store.completeRetrival(with: feed.localRepresentation, timestamp: experationTimeStamp)
        XCTAssertEqual(store.recievedMessages, [.retrive])
    }
    
    func test_load_hasNoSideEffectsOnCacheExpiration() {
        let feed  = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let (store, sut) = makeSUT(currentDate: { fixedCurrentDate })
        let experationTimeStamp = fixedCurrentDate
            .minusFeedCacheMaxAge()
        sut.load { (_) in
            
        }
        store.completeRetrival(with: feed.localRepresentation, timestamp: experationTimeStamp)
        XCTAssertEqual(store.recievedMessages, [.retrive])
    }
    
    func test_load_hasNoSideOnExpiredCache() {
        let feed  = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let (store, sut) = makeSUT(currentDate: { fixedCurrentDate })
        let experationTimeStamp = fixedCurrentDate
            .minusFeedCacheMaxAge()
            .adding(seconds: -1)
        sut.load { (_) in
            
        }
        store.completeRetrival(with: feed.localRepresentation, timestamp: experationTimeStamp)
        XCTAssertEqual(store.recievedMessages, [.retrive])
    }
    
    func test_load_doesnNotDeliverValueAfterSUTHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoder? = LocalFeedLoder(with: store, currentDate: Date.init)
        var recievedResults = [LocalFeedLoder.LoadResult]()
        sut?.load(completion: { recievedResults.append($0)})
        
        sut = nil
        
        store.completeWithEmptyCache()
        XCTAssertTrue(recievedResults.isEmpty)
    }
    
    func makeSUT(currentDate: @escaping () -> Date = Date.init) -> (FeedStoreSpy, LocalFeedLoder) {
        let store = FeedStoreSpy()
        let loader = LocalFeedLoder(with: store, currentDate: currentDate)
        trackForMemoryLeak(object: store)
        trackForMemoryLeak(object: loader)
        return (store, loader)
    }
    
    func expect(_ sut: LocalFeedLoder,
                toCompleteWithResult expectedResult: FeedLoader.Result,
                when: ()->(),
                file: StaticString = #file,
                line: UInt = #line) {
        
        let exp = XCTestExpectation()
        
        sut.load { (recievedResult) in
            switch (recievedResult, expectedResult) {
            case let(.success(recievedImages), .success(expectedResult)):
                XCTAssertEqual(recievedImages, expectedResult, file: file, line: line)
            case let (.failure(recievedError), .failure(expectedError)):
                XCTAssertEqual(recievedError as NSError?, expectedError as NSError?, file: file, line: line)
            default:
                XCTFail()
            }
            exp.fulfill()
        }
        
        when()
        
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


