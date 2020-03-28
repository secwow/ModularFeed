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

class LocalFeedLoder {
    let feedStore: FeedStore
    
    init(with feedStore: FeedStore) {
        self.feedStore = feedStore
    }
    
    func save(items: [FeedItem]) {
        feedStore.deleteCachedFeed()
    }
}

class FeedStore {
    var deletedCachedFeedCallCount = 0
    var insertCallCount = 0
    
    
    func deleteCachedFeed() {
        deletedCachedFeedCallCount += 1
    }
    
    func completeDeletion(with error: Error, at index: Int = 0) {
        
    }
    
}

class CacheFeedUseCaseTests: XCTestCase {
    
    func test_init_doesnNotDeleteUponCreation() {
        let (store, _) = makeSUT()
        
        XCTAssertEqual(store.deletedCachedFeedCallCount, 0)
    }
    
    func test_save_requestCacheDeletion() {
        let (store, loader) = makeSUT()
        
        let items = [uniqueItem(), uniqueItem()]
        loader.save(items: items)
        XCTAssertEqual(store.deletedCachedFeedCallCount, 1)
    }
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (store, loader) = makeSUT()
        
        let items = [uniqueItem(), uniqueItem()]
        let deletionError = anyNSError()
        loader.save(items: items)
        store.completeDeletion(with: deletionError)
        XCTAssertEqual(store.insertCallCount, 1)
    }
    
    func makeSUT() -> (FeedStore, LocalFeedLoder) {
        let store = FeedStore()
        let loader = LocalFeedLoder(with: store)
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
