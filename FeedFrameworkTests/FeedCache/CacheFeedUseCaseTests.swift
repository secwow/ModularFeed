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
        
        let exp = XCTestExpectation(description: "Wait to validation")
        sut.validateCache() {
            exp.fulfill()
        }
        
        store.completeWithEmptyCache()
        
        wait(for: [exp], timeout: 1.0)
    
        XCTAssertEqual(store.recievedMessages, [.retrive])
    }
    
    func test_validateCache_doesNotDeleteCachedImagesLessThanSevenDaysOld() {
        let feed  = uniqueImageFeed()
        let fixedCurrentDate = Date()
        
        let (store, sut) = makeSUT(currentDate: { fixedCurrentDate })
        let lessThatSevenDaysOldTimestamp = fixedCurrentDate
            .adding(days: -7)
            .adding(seconds: 1)
    
        sut.validateCache()
        store.completeRetrival(with: feed.localRepresentation, timestamp: lessThatSevenDaysOldTimestamp)
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
