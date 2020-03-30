import FeedFramework
import XCTest

class LoadFeedFromCacheUseCaseTest: XCTestCase {
    func test_init_doesnNotMessageDeleteUponCreation() {
        let (store, _) = makeSUT()
        
        XCTAssertEqual(store.recievedMessages, [])
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
