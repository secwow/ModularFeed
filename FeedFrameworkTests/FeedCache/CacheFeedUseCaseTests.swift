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
    
    
    func deleteCachedFeed() {
        deletedCachedFeedCallCount += 1
    }
}

class CacheFeedUseCaseTests: XCTestCase {
    
    func test_init_doesnNotDeleteUponCreation() {
        let store = FeedStore()
        let loader = LocalFeedLoder(with: store)

        
        XCTAssertEqual(store.deletedCachedFeedCallCount, 0)
    }
    
    func test_save_requestCacheDeletion() {
        let store = FeedStore()
        let loader = LocalFeedLoder(with: store)
        let items = [uniqueItem(), uniqueItem()]
        loader.save(items: items)
        XCTAssertEqual(store.deletedCachedFeedCallCount, 1)
    }
    
    func uniqueItem() -> FeedItem {
        return FeedItem(id: UUID(), description: "fds", location: "fds", imageURL: URL(string: "http://some.url")!)
    }
    
}
