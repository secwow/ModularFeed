//
//  FeedFrameworkTests.swift
//  FeedFrameworkTests
//
//  Created by AndAdmin on 25.03.2020.
//  Copyright © 2020 AndAdmin. All rights reserved.
//

import XCTest
import FeedFramework

//As an offline customer
//I want the app to show the latest saved version of my image feed
//So I can always enjoy images of my friends


//Given the customer doesn't have connectivity
//  And there’s a cached version of the feed
//  And the cache is less than seven days old
// When the customer requests to see the feed
// Then the app should display the latest feed saved
//
//Given the customer doesn't have connectivity
//  And there’s a cached version of the feed
//  And the cache is seven days old or more
// When the customer requests to see the feed
// Then the app should display an error message
//
//Given the customer doesn't have connectivity
//  And the cache is empty
// When the customer requests to see the feed
// Then the app should display an error message

//Cache Feed Use Case
//Data:
//Feed items

//Primary course (happy path):
//Execute "Save Feed Items" command with above data.
//System deletes old cache data.
//System encodes feed items.
//System timestamps the new cache.
//System saves new cache data.
//System delivers success message.

//Deleting error course (sad path):
//System delivers error.

//Saving error course (sad path):
//System delivers error.

class FeedStoreSpy: FeedStore {
    typealias DeleteCacheCompletion = (Error?) -> ()
    typealias InsertionCompletion = (Error?) -> ()
    private var deletionCompletions: [DeleteCacheCompletion] = []
    private var insertionCompletions: [InsertionCompletion] = []
    private(set) var recievedMessages: [RecivedMessage] = []
    
    enum RecivedMessage: Equatable {
        case deleteCacheFeedMessage
        case insert([FeedItem], Date)
    }
    
    func deleteCachedFeed(completion: @escaping (Error?) -> ()) {
        deletionCompletions.append(completion)
        recievedMessages.append(.deleteCacheFeedMessage)
    }
    
    func insert(_ feedItems: [FeedItem], timestamp: Date, completion: @escaping InsertionCompletion) {
        insertionCompletions.append(completion)
        recievedMessages.append(.insert(feedItems, timestamp))
    }
    
    func completeDeletion(with error: Error, at index: Int = 0) {
        deletionCompletions[index](error)
    }
    
    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
    }
    
    func completeInsertion(with error: Error, at index: Int = 0) {
        insertionCompletions[index](error)
    }
    
    func completeInsertionSuccessfully(at index: Int = 0) {
        insertionCompletions[index](nil)
    }
}

class CacheFeedUseCaseTests: XCTestCase {
    
    func test_init_doesnNotMessageDeleteUponCreation() {
        let (store, _) = makeSUT()
        
        XCTAssertEqual(store.recievedMessages, [])
    }
    
    func test_save_requestCacheDeletion() {
        let (store, loader) = makeSUT()
        
        let items = [uniqueItem(), uniqueItem()]
        loader.save(items: items)
        XCTAssertEqual(store.recievedMessages, [.deleteCacheFeedMessage])
    }
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (store, loader) = makeSUT()
        
        let items = [uniqueItem(), uniqueItem()]
        let deletionError = anyNSError()
        loader.save(items: items)
        store.completeDeletion(with: deletionError)
        XCTAssertEqual(store.recievedMessages, [.deleteCacheFeedMessage])
    }
    
    func test_save_requestsNewCacheInsertionWithTimestampOnSuccessfullDeletion() {
        let timestamp = Date()
        let (store, loader) = makeSUT(currentDate: { timestamp })
        
        let items = [uniqueItem(), uniqueItem()]
        
        loader.save(items: items)
        store.completeDeletionSuccessfully()
        XCTAssertEqual(store.recievedMessages, [.deleteCacheFeedMessage, .insert(items, timestamp)])
    }
    
    func test_save_failOnDeletionError() {
        let timestamp = Date()
        let (store, loader) = makeSUT(currentDate: { timestamp })
        let deletionError = anyNSError()
        
        expect(loader, toCompleteWithError: deletionError, when: {
            store.completeDeletion(with: deletionError)
        })
    }
    
    func test_save_failsOnInsertionError() {
        let (store, loader) = makeSUT()
        let insertionError = anyNSError()
        
        expect(loader, toCompleteWithError: insertionError, when: {
            store.completeDeletionSuccessfully()
            store.completeInsertion(with: insertionError)
        })
    }
    
    func test_save_succsedOnSuccessfulInsetion() {
        let (store, loader) = makeSUT()
        
        expect(loader, toCompleteWithError: nil, when: {
            store.completeDeletionSuccessfully()
            store.completeInsertionSuccessfully()
        })
    }
    
    func test_save_doesntDeliverSUTErrorAfterInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var loader: LocalFeedLoder? = LocalFeedLoder(with: store, currentDate: Date.init)
        
        var recivedResults = [Error?]()
        
        loader?.save(items: [uniqueItem()]) { error in
            recivedResults.append(error)
        }
        
        loader = nil
        
        store.completeDeletion(with: anyNSError())
        XCTAssertTrue(recivedResults.isEmpty)
    }
    
    func test_save_doesntDeliverSUTInsertionErrorAfterInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var loader: LocalFeedLoder? = LocalFeedLoder(with: store, currentDate: Date.init)
        
        var recivedResults = [Error?]()
        
        loader?.save(items: [uniqueItem()]) { error in
            recivedResults.append(error)
        }
        
        store.completeDeletionSuccessfully()
        
        loader = nil
        
        store.completeInsertion(with: anyNSError())
        XCTAssertTrue(recivedResults.isEmpty)
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
    
    func makeSUT(currentDate: @escaping () -> Date = Date.init) -> (FeedStoreSpy, LocalFeedLoder) {
        let store = FeedStoreSpy()
        let loader = LocalFeedLoder(with: store, currentDate: currentDate)
        trackForMemoryLeak(object: store)
        trackForMemoryLeak(object: loader)
        return (store, loader)
    }
    
    func uniqueItem() -> FeedItem {
        return FeedItem(id: UUID(), description: "fds", location: "fds", imageURL: URL(string: "http://some.url")!)
    }
    
    private func anyURL() -> URL {
        return URL(string: "http://image.url")!
    }
    private func anyNSError() -> NSError {
        return NSError(domain: "", code: 0, userInfo: nil)
    }
    
}
