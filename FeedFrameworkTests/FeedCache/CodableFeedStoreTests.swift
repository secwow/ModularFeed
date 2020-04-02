import FeedFramework
import XCTest

//Insert
//    - [V] To empty cache works
//    - To non-empty cache overrides previous value
//    - Error (if possible to simulate, e.g., no write permission)
//
//- Retrieve
//    - Empty cache works (before something is inserted)
//    - Non-empty cache returns data
//    - Non-empty cache twice returns same data (retrieve should have no side-effects)
//    - Error (if possible to simulate, e.g., invalid data)
//
//- Delete
//    - Empty cache does nothing (cache stays empty and does not fail)
//    - Inserted data leaves cache empty
//    - Error (if possible to simulate, e.g., no write permission)
//
//- Side-effects must run serially to avoid race-conditions (deleting the wrong cache... overriding the latest data...)

class CodableFeedStore {
    private struct Cache: Codable {
        let feed: [CodableFeedImage]
        let timestamp: Date
        
        var localFeed: [LocalFeedImage] {
            return feed.map({$0.local})
        }
    }
    
    public struct CodableFeedImage: Codable  {
        private let id: UUID
        private let description: String?
        private let location: String?
        private let url: URL
        
        init(_ image: LocalFeedImage) {
            self.id = image.id
            self.description = image.description
            self.location = image.location
            self.url = image.url
        }
        
        var local: LocalFeedImage {
            return LocalFeedImage(id: id, description: description, location: location, url: url)
        }
    }
    
    private let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-Feed.store")
    
    func retrieve(completion: @escaping FeedStore.RetrivalCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            completion(.empty)
            return
        }
        
        let decoder = JSONDecoder()
        let cache = try! decoder.decode(Cache.self, from: data)
        
        completion(.found(feed: cache.localFeed, timestamp: cache.timestamp ))
    }
    
    func insert(_ feedItems: [LocalFeedImage], timestamp: Date, completion: @escaping FeedStore.InsertionCompletion) {
        let encoder = JSONEncoder()
        let cache = Cache(feed: feedItems.map(CodableFeedImage.init), timestamp: timestamp)
        let encoded = try! encoder.encode(cache)
        try! encoded.write(to: storeURL)
        completion(nil)
    }
}

class CodableFeedStoreTests: XCTestCase {
    override func setUp() {
        super.tearDown()
        self.cleanCache()
    }
    
    override func tearDown() {
        super.tearDown()
        self.cleanCache()
    }
    
    private func cleanCache() {
        let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-Feed.store")
        try? FileManager.default.removeItem(at: storeURL)
    }
    
    func test_retrive_deliversEmptyOnEmptyCache() {
        let sut = CodableFeedStore()
        let exp = XCTestExpectation()
        
        sut.retrieve { result in
            switch result {
            case .empty:
                break
            default:
                XCTFail("Wait for empty but got \(result) instead")
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_retrive_hasNoSideEffectsONEmptyCacheTwice() {
        let sut = CodableFeedStore()
        let exp = XCTestExpectation()
        
        sut.retrieve { firstResult in
            sut.retrieve { (secondResult) in
                switch (firstResult, secondResult) {
                    
                case (.empty, .empty):
                    break
                default:
                    XCTFail("Wait for empty twice but got \(firstResult) and \(secondResult) instead")
                }
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_retriveAfterInsertingToEmptyCache_deliversInsertedValue() {
        let sut = CodableFeedStore()
        let exp = XCTestExpectation()
        let timeStamp = Date()
        let insertedFeed = uniqueImageFeed()
        sut.insert(insertedFeed.localRepresentation, timestamp: timeStamp) { insertionError in
            sut.retrieve { (result) in
                switch result {
                case let .found(feed, recievedTimestamp):
                    XCTAssertEqual(feed, insertedFeed.localRepresentation)
                    XCTAssertEqual(timeStamp, recievedTimestamp)
                default:
                    XCTFail("Expected found with feed, but got \(result) instead")
                }
                exp.fulfill()
            }
        }
        
        wait(for: [exp], timeout: 1.0)
    }
}

