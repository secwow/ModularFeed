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
    
    func test_load_hasNoSideEffectOnCachedImagesOnLessThanSevenDaysOldCache() {
        let feed  = uniqueImageFeed()
        let fixedCurrentDate = Date()
        
        let (store, sut) = makeSUT(currentDate: { fixedCurrentDate })
        let lessThatSevenDaysOldTimestamp = fixedCurrentDate
            .adding(days: -7)
            .adding(seconds: 1)
        
        self.expect(sut, toCompleteWithResult: .success(feed.models), when: {
            store.completeRetrival(with: feed.localRepresentation, timestamp: lessThatSevenDaysOldTimestamp)
        })
    }
    
    func test_load_deliversNoCachedImagesOnSevenDaysOldCache() {
        let feed  = uniqueImageFeed()
        let fixedCurrentDate = Date()
        
        let (store, sut) = makeSUT(currentDate: { fixedCurrentDate })
        let sevenDaysOldTimestamp = fixedCurrentDate
            .adding(days: -7)
        
        self.expect(sut, toCompleteWithResult: .success([]), when: {
            store.completeRetrival(with: feed.localRepresentation, timestamp: sevenDaysOldTimestamp)
        })
    }
    
    func test_load_deliversNoCachedImagesOnMoreThanSevenDaysOldCache() {
        let feed  = uniqueImageFeed()
        let fixedCurrentDate = Date()
        
        let (store, sut) = makeSUT(currentDate: { fixedCurrentDate })
        let noreThanSevenDaysOldTimestamp = fixedCurrentDate
            .adding(days: -7)
            .adding(seconds: -1)
        
        self.expect(sut, toCompleteWithResult: .success([]), when: {
            store.completeRetrival(with: feed.localRepresentation, timestamp: noreThanSevenDaysOldTimestamp)
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
    
    func test_load_doesNotDeleteCacheOnLessThatSevenDaysOld() {
        let feed  = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let (store, sut) = makeSUT(currentDate: { fixedCurrentDate })
        let lessThatSevenDaysOldTimestamp = fixedCurrentDate
            .adding(days: -7)
            .adding(seconds: 1)
        sut.load { (_) in
            
        }
        store.completeRetrival(with: feed.localRepresentation, timestamp: lessThatSevenDaysOldTimestamp)
        XCTAssertEqual(store.recievedMessages, [.retrive])
    }
    
    func test_load_hasNoSideEffectsOnSevenDaysOldCache() {
        let feed  = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let (store, sut) = makeSUT(currentDate: { fixedCurrentDate })
        let lessThatSevenDaysOldTimestamp = fixedCurrentDate
            .adding(days: -7)
        sut.load { (_) in
            
        }
        store.completeRetrival(with: feed.localRepresentation, timestamp: lessThatSevenDaysOldTimestamp)
        XCTAssertEqual(store.recievedMessages, [.retrive])
    }
    
    func test_load_hasNoSideOnMoreThatSevenDaysOldCache() {
        let feed  = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let (store, sut) = makeSUT(currentDate: { fixedCurrentDate })
        let lessThatSevenDaysOldTimestamp = fixedCurrentDate
            .adding(days: -7)
            .adding(seconds: -1)
        sut.load { (_) in
            
        }
        store.completeRetrival(with: feed.localRepresentation, timestamp: lessThatSevenDaysOldTimestamp)
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
                toCompleteWithResult expectedResult: LoadFeedResult,
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
}
