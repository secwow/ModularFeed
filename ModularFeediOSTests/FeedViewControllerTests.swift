//
//  ModularFeediOSTests.swift
//  ModularFeediOSTests
//
//  Created by AndAdmin on 05.04.2020.
//  Copyright © 2020 AndAdmin. All rights reserved.
//

import XCTest
import FeedFramework
import ModularFeediOS

class FeedViewControllerTests: XCTestCase {
    func test_viewDidLoad_loadFeed() {
        let (sut, loader) = makeSUT()
        XCTAssertEqual(loader.loadFeedCount, 0)
        sut.loadViewIfNeeded()
        
        XCTAssertEqual(loader.loadFeedCount, 1)
        
        sut.simulatePullToRefresh()
        XCTAssertEqual(loader.loadFeedCount, 2)
        sut.simulatePullToRefresh()
        XCTAssertEqual(loader.loadFeedCount, 3)
    }
    
    func test_viewDidLoad_showsLoadingIndicator() {
        let (sut, _) = makeSUT()
        sut.loadViewIfNeeded()
        
        XCTAssertEqual(sut.refreshControl?.isRefreshing, true)
    }
    
    func test_viewDidLoad_hidesLoadingIndicatorWhenLoadingIsEnded() {
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()
        loader.completeLoad(with: .success([]))
        XCTAssertEqual(sut.refreshControl?.isRefreshing, false)
    }
    
    func test_userInitiatedFeedReload_hidesLoadingIndicatorWhenLoadingIsEnded() {
        let (sut, loader) = makeSUT()
        sut.simulatePullToRefresh()
        XCTAssertEqual(sut.refreshControl?.isRefreshing, true)
        loader.completeLoad(with: .success([]))
        XCTAssertEqual(sut.refreshControl?.isRefreshing, false)
    }
    
    func makeSUT() -> (FeedViewController, LoaderSpy) {
        let loader = LoaderSpy()
        let sut = FeedViewController(loader: loader)
        return (sut, loader)
    }
    
    class LoaderSpy: FeedLoader {
        private var loadCompletions = [(FeedLoader.Result) -> ()]()
        
        var loadFeedCount: Int {
            return self.loadCompletions.count
        }
        
        func load(completion: @escaping (FeedLoader.Result) -> ()) {
            self.loadCompletions.append(completion)
        }
        
        func completeLoad(with result: FeedLoader.Result, at index: Int = 0) {
            self.loadCompletions[index](result)
        }
    }
}

extension FeedViewController {
    func simulatePullToRefresh() {
        refreshControl?.allTargets.forEach({ target in
            refreshControl?.actions(forTarget: target, forControlEvent: .valueChanged)?.forEach({ (selector) in
                (target as NSObject).perform(Selector(selector))
            })
        })
    }
}
