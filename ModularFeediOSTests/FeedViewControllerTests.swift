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
        
        sut.simulatePullLoading()
        XCTAssertEqual(loader.loadFeedCount, 2)
        
        sut.simulatePullLoading()
        XCTAssertEqual(loader.loadFeedCount, 3)
    }
    
    func test_userInitiatedFeedReload_hidesLoadingIndicatorWhenLoadingIsEnded() {
        let (sut, loader) = makeSUT()
        
        sut.simulatePullLoading()
        XCTAssertTrue(sut.isShownLoadingIndicator)
        
        loader.completeLoad(with: .success([]))
        XCTAssertFalse(sut.isShownLoadingIndicator)
    }
    
    func test_loadFeedCompletion_rendersSuccessfullyLoadedFeed() {
        let (sut, loader) = makeSUT()
        let image1 =  makeImage(description: "some", location: "some")
        let image2 = makeImage(description: nil, location: "some")
        let image3 = makeImage(description: "Some", location: nil)
        let image4 = makeImage(description: nil, location: nil)
        
        sut.loadViewIfNeeded()
        XCTAssertEqual(sut.numberRenderedFeedImageViews, 0)
        
        loader.completeLoad(with: .success([image1]))
        XCTAssertEqual(sut.numberRenderedFeedImageViews, 1)
        assertThat(sut, isRendering: [image1])
        
        sut.simulatePullLoading()
        loader.completeLoad(with: .success([image1, image2, image3, image4]))
        assertThat(sut, isRendering: [image1, image2, image3, image4])
    }
    
    func test_loadFeedCompletion_doesNotAlterCurrentRenderingStateOnError() {
        let (sut, loader) = makeSUT()
        let image1 =  makeImage(description: "some", location: "some")
        sut.loadViewIfNeeded()
        loader.completeLoad(with: .success([image1]))
        XCTAssertEqual(sut.numberRenderedFeedImageViews, 1)
        assertThat(sut, isRendering: [image1])
        
        sut.simulatePullLoading()
        loader.completeLoad(with: .failure(anyNSError()))
        assertThat(sut, isRendering: [image1])
    }
    
    func makeSUT(file: StaticString = #file, line: UInt = #line) -> (FeedViewController, LoaderSpy) {
        let loader = LoaderSpy()
        let sut = FeedViewController(loader: loader)
        trackForMemoryLeak(object: loader)
        trackForMemoryLeak(object: sut)
        return (sut, loader)
    }
    
    private func assertThat(_ sut: FeedViewController, isRendering feed: [FeedImage], file: StaticString = #file, line: UInt = #line) {
        guard sut.numberRenderedFeedImageViews == feed.count else {
            return XCTFail("Expected \(feed.count) images, got \(sut.numberRenderedFeedImageViews) instead.", file: file, line: line)
        }

        feed.enumerated().forEach { index, image in
            assertThat(sut, hasViewConfiguredFor: image, at: index, file: file, line: line)
        }
    }
    
    private func assertThat(_ sut: FeedViewController, hasViewConfiguredFor image: FeedImage, at index: Int, file: StaticString = #file, line: UInt = #line) {
        let view = sut.feedImageView(at: index)
        
        guard let cell = view as? FeedImageViewCell else {
            return XCTFail("Expected \(FeedImageViewCell.self) instance, got \(String(describing: view)) instead", file: file, line: line)
        }
        
        let shouldLocationBeVisible = (image.location != nil)
        XCTAssertEqual(cell.isShowingLocation, shouldLocationBeVisible, "Expected `isShowingLocation` to be \(shouldLocationBeVisible) for image view at index (\(index))", file: file, line: line)
        
        XCTAssertEqual(cell.locationText, image.location, "Expected location text to be \(String(describing: image.location)) for image  view at index (\(index))", file: file, line: line)
        
        XCTAssertEqual(cell.descriptionText, image.description, "Expected description text to be \(String(describing: image.description)) for image view at index (\(index)", file: file, line: line)
    }
    
    func makeImage(description: String? = nil, location: String? = nil, url: URL = URL(string: "http://someurl.com")!) -> FeedImage {
        return FeedImage(id: UUID(), description: description, location: location, url: url)
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
    func simulatePullLoading() {
        refreshControl?.simulatePullToRefresh()
    }
    
    var isShownLoadingIndicator: Bool {
        return refreshControl?.isRefreshing == true
    }
    
    var numberRenderedFeedImageViews: Int {
        return tableView.numberOfRows(inSection: feedImageSection)
    }
    
    var feedImageSection: Int {
        return 0
    }
    
    func feedImageView(at: Int) -> UITableViewCell? {
        let ds = tableView.dataSource
        let index = IndexPath(row: at, section: 0)
        return ds?.tableView(tableView, cellForRowAt: index)
    }
}

private extension FeedImageViewCell {
    func simulateRetryAction() {
        feedImageRetryButton.simulateTap()
    }
    
    var isShowingLocation: Bool {
        return !locationContainer.isHidden
    }
    
    var isShowingImageLoadingIndicator: Bool {
        return feedImageContainer.isShimmering
    }
    
    var isShowingRetryAction: Bool {
        return !feedImageRetryButton.isHidden
    }
    
    var locationText: String? {
        return locationLabel.text
    }
    
    var descriptionText: String? {
        return descriptionLabel.text
    }
    
    var renderedImage: Data? {
        return feedImageView.image?.pngData()
    }
}

private extension  UIRefreshControl {
    func simulatePullToRefresh() {
        allTargets.forEach({ target in
            actions(forTarget: target, forControlEvent: .valueChanged)?.forEach({ (selector) in
                (target as NSObject).perform(Selector(selector))
            })
        })
    }
}

private extension  UIButton {
    func simulateTap() {
        allTargets.forEach({ target in
            actions(forTarget: target, forControlEvent: .touchUpInside)?.forEach({ (selector) in
                (target as NSObject).perform(Selector(selector))
            })
        })
    }
}
