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
    init(with feedStore: FeedStore) {
        
    }
}

class FeedStore {
    var deletedCachedFeedCallCount = 0
}

class CacheFeedUseCaseTests: XCTestCase {
    
    func test_init_doesnNotDeleteUponCreation() {
        let store = FeedStore()
        let loader = LocalFeedLoder(with: store)
        
        XCTAssertEqual(store.deletedCachedFeedCallCount, 0)
    }
    
}
