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
        let exp = XCTestExpectation(description: "Wait to retrival")
        let retrivalError = anyNSError()
        
        var receivedError: Error?
        sut.load() { result in
            switch result {
            case let .failure(error):
                receivedError = error
            default:
                XCTFail()
            }
            exp.fulfill()
        }
        
        store.completeRetrival(with: retrivalError)
        
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(receivedError as NSError?, retrivalError)
    }
    
    func test_load_deliversNoErrorOnEmptyCache() {
        let (store, sut) = makeSUT()
        let exp = XCTestExpectation(description: "Wait to retrival")
        let retrivalError = anyNSError()
        
        var receivedFeed: [FeedImage]?
        sut.load() { result in
            switch result {
            case let .success(feed):
                receivedFeed = feed
            default:
                XCTFail()
            }
            exp.fulfill()
        }
        
        store.completeWithEmptyCache()
        
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(receivedFeed, [])
    }
    
    func makeSUT(currentDate: @escaping () -> Date = Date.init) -> (FeedStoreSpy, LocalFeedLoder) {
        let store = FeedStoreSpy()
        let loader = LocalFeedLoder(with: store, currentDate: currentDate)
        trackForMemoryLeak(object: store)
        trackForMemoryLeak(object: loader)
        return (store, loader)
    }
    
    func expect(_ sut: LocalFeedLoder,
                toCompleteWithError error: Error?,
                when: ()->(),
                file: StaticString = #file,
                line: UInt = #line) {
        
        let exp = XCTestExpectation()
        
        var recievedError: Error?
        sut.save(items: [uniqueItem(), uniqueItem()]) {error in
            recievedError = error
            exp.fulfill()
        }
        
        when()
        
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(error as NSError?, recievedError as NSError?, file:file, line: line)
    }
    
    func uniqueItem() -> FeedImage {
        return FeedImage(id: UUID(), description: "fds", location: "fds", url: URL(string: "http://some.url")!)
    }
    
    
    func uniqueItems() -> (models: [FeedImage], localRepresentation: [LocalFeedImage]) {
        let items = [uniqueItem(), uniqueItem()]
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
