import XCTest
import FeedFramework

class CacheFeedUseCaseTests: XCTestCase {
    
    func test_init_doesnNotMessageDeleteUponCreation() {
        let (store, _) = makeSUT()
        
        XCTAssertEqual(store.recievedMessages, [])
    }
    
    func test_validateCache_onRetrivalError() {
        let (store, sut) = makeSUT()
        
        sut.validateCache()
        store.completeRetrival(with: anyNSError())
        
        XCTAssertEqual(store.recievedMessages, [.retrive, .deleteCacheFeedMessage])
    }
    
    func test_validate_shouldNotDeleteCacheIfEmptyCache() {
        let (store, sut) = makeSUT()
        sut.validateCache()
        store.completeWithEmptyCache()
        
        XCTAssertEqual(store.recievedMessages, [.retrive])
    }
    
    func test_validateCache_doesNotDeleteNonExpiredCache() {
        let feed  = uniqueImageFeed()
        let fixedCurrentDate = Date()
        
        let (store, sut) = makeSUT(currentDate: { fixedCurrentDate })
        let expirationDate = fixedCurrentDate
            .minusFeedCacheMaxAge()
            .adding(seconds: 1)
        
        sut.validateCache()
        store.completeRetrival(with: feed.localRepresentation, timestamp: expirationDate)
        XCTAssertEqual(store.recievedMessages, [.retrive])
    }
    
    func test_validateCache_deletesOnCacheExpiration() {
        let feed  = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let (store, sut) = makeSUT(currentDate: { fixedCurrentDate })
        let expiringDate = fixedCurrentDate
            .minusFeedCacheMaxAge()
        sut.validateCache()
        store.completeRetrival(with: feed.localRepresentation, timestamp: expiringDate)
        XCTAssertEqual(store.recievedMessages, [.retrive, .deleteCacheFeedMessage])
    }
    
    func test_validateCache_deletesExpiredCache () {
        let feed  = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let (store, sut) = makeSUT(currentDate: { fixedCurrentDate })
        let expiredDate = fixedCurrentDate
            .minusFeedCacheMaxAge()
            .adding(seconds: -1)
        sut.validateCache()
        store.completeRetrival(with: feed.localRepresentation, timestamp: expiredDate)
        XCTAssertEqual(store.recievedMessages, [.retrive, .deleteCacheFeedMessage])
    }
    
    func test_load_doesNotDeleteInvalidCacheAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoder? = LocalFeedLoder(with: store, currentDate: Date.init)
        sut?.validateCache()
        
        sut = nil
        
        store.completeWithEmptyCache()
        XCTAssertEqual(store.recievedMessages, [.retrive])
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
    
    func makeSUT(currentDate: @escaping () -> Date = Date.init) -> (FeedStoreSpy, LocalFeedLoder) {
        let store = FeedStoreSpy()
        let loader = LocalFeedLoder(with: store, currentDate: currentDate)
        trackForMemoryLeak(object: store)
        trackForMemoryLeak(object: loader)
        return (store, loader)
    }
}
