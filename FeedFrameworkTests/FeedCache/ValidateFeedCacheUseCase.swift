//
//  ValidateFeedCacheUseCase.swift
//  FeedFrameworkTests
//
//  Created by AndAdmin on 02.04.2020.
//  Copyright © 2020 AndAdmin. All rights reserved.
//

import Foundation
import FeedFramework
import XCTest

class ValidateFeedCacheUseCase: XCTestCase {
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
