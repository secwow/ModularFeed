import Foundation
import FeedFramework
import XCTest

//### Validate Feed Cache Use Case
//
//#### Primary course:
//1. Execute "Validate Cache" command with above data.
//2. System retrieves feed data from cache.
//3. System validates cache is less than seven days old.
//
//#### Retrieval error course (sad path):
//1. System deletes cache.
//
//#### Expired cache course (sad path):
//1. System deletes cache.


class ValidateFeedCacheUseCase: XCTestCase {
    func test_init_doesnNotMessageDeleteUponCreation() {
        let (store, _) = makeSUT()
        
        XCTAssertEqual(store.recievedMessages, [])
    }
    
    func test_validate_doesNotDeleteEmptyCache() {
        let (store, sut) = makeSUT()
        sut.validateCache()
        XCTAssertEqual(store.recievedMessages, [.retrive])
    }
    
    func test_validate_deleteCacheOnRetrievError() {
        let fixedCurrentDate = Date()
        let (store, sut) = makeSUT(currentDate: { fixedCurrentDate })

        sut.validateCache()
        store.completeRetrival(with: anyNSError())
        XCTAssertEqual(store.recievedMessages, [.retrive, .deleteCacheFeedMessage])
    }
     
     func test_validate_doesNotDeleteCacheOnNonExpiredCache() {
         let feed  = uniqueImageFeed()
         let fixedCurrentDate = Date()
         let (store, sut) = makeSUT(currentDate: { fixedCurrentDate })
         let experationTimeStamp = fixedCurrentDate
             .minusFeedCacheMaxAge()
             .adding(seconds: 1)
         sut.validateCache()
         store.completeRetrival(with: feed.localRepresentation, timestamp: experationTimeStamp)
         XCTAssertEqual(store.recievedMessages, [.retrive])
     }
     
     func test_validate_hasNoSideEffectsOnCacheExpiration() {
         let feed  = uniqueImageFeed()
         let fixedCurrentDate = Date()
         let (store, sut) = makeSUT(currentDate: { fixedCurrentDate })
         let experationTimeStamp = fixedCurrentDate
             .minusFeedCacheMaxAge()
        sut.validateCache()
        store.completeRetrival(with: feed.localRepresentation, timestamp: experationTimeStamp)
        XCTAssertEqual(store.recievedMessages, [.retrive, .deleteCacheFeedMessage])
     }
     
     func test_validate_hasNoSideOnExpiredCache() {
         let feed  = uniqueImageFeed()
         let fixedCurrentDate = Date()
         let (store, sut) = makeSUT(currentDate: { fixedCurrentDate })
         let experationTimeStamp = fixedCurrentDate
             .minusFeedCacheMaxAge()
             .adding(seconds: -1)
         sut.validateCache()
         store.completeRetrival(with: feed.localRepresentation, timestamp: experationTimeStamp)
         XCTAssertEqual(store.recievedMessages, [.retrive, .deleteCacheFeedMessage])
     }
     
     func test_validate_doesnNotDeliverValueAfterSUTHasBeenDeallocated() {
         let store = FeedStoreSpy()
         var sut: LocalFeedLoder? = LocalFeedLoder(with: store, currentDate: Date.init)
         var recievedResults = [LocalFeedLoder.LoadResult]()
         sut?.validateCache()
         
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
    
    private func uniqueImage() -> FeedImage {
        return FeedImage(id: UUID(), description: "fds", location: "fds", url: URL(string: "http://some.url")!)
    }
    
    
    private func uniqueImageFeed() -> (models: [FeedImage], localRepresentation: [LocalFeedImage]) {
        let items: [FeedImage] = [uniqueImage(), uniqueImage()]
        let localItems = items.map{ LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)}
        return (items, localItems)
    }
    
    private func anyURL() -> URL {
        return URL(string: "http://image.url")!
    }
    private func anyNSError() -> NSError {
        return NSError(domain: "", code: 0, userInfo: nil)
    }
}
