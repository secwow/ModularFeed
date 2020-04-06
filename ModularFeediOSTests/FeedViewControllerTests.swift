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
        sut.loadViewIfNeeded()
        XCTAssertTrue(sut.isShownLoadingIndicator)
        loader.completeLoad(with: .success([]), at: 0)
        XCTAssertFalse(sut.isShownLoadingIndicator)
        
        
        sut.simulatePullLoading()
        XCTAssertTrue(sut.isShownLoadingIndicator)
        loader.completeLoad(with: .success([]), at: 1)
        XCTAssertFalse(sut.isShownLoadingIndicator)
        
        sut.simulatePullLoading()
        XCTAssertTrue(sut.isShownLoadingIndicator)
        loader.completeLoad(with: .failure(anyNSError()), at: 2)
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
    
    func test_feedImageView_loadImageURLWhenVisible() {
        let (sut, loader) = makeSUT()
        let image = makeImage(url: URL(string: "http://url-1.com")!)
        let image2 = makeImage(url: URL(string: "http://url-2.com")!)
        
        sut.loadViewIfNeeded()
        loader.completeLoad(with: .success([image, image2]), at: 0)
        XCTAssertEqual(loader.loadedImageURLs, [])
        sut.simulateImageFeedViewVisible(at: 0)
        sut.simulateImageFeedViewVisible(at: 1)
        XCTAssertEqual(loader.loadedImageURLs, [image.url, image2.url])
    }
    
    func test_feedImageView_cancelsImageLoadingWhenNotVisibleAnymore() {
        let (sut, loader) = makeSUT()
        let image = makeImage(url: URL(string: "http://url-1.com")!)
        let image2 = makeImage(url: URL(string: "http://url-2.com")!)
        
        sut.loadViewIfNeeded()
        loader.completeLoad(with: .success([image, image2]), at: 0)
        XCTAssertEqual(loader.cancelledImageURLs, [])
        sut.simulateFeedImageViewNotVisible(at: 0)
        XCTAssertEqual(loader.cancelledImageURLs, [image.url])
        sut.simulateFeedImageViewNotVisible(at: 1)
        XCTAssertEqual(loader.cancelledImageURLs, [image.url, image2.url])
    }
    
    func makeSUT(file: StaticString = #file, line: UInt = #line) -> (FeedViewController, LoaderSpy) {
        let loader = LoaderSpy()
        let sut = FeedViewController(loader: loader, imageLoader: loader)
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
    
    class LoaderSpy: FeedLoader, FeedImageDataLoader {
        private var loadCompletions = [(FeedLoader.Result) -> ()]()
        var loadedImageURLs: [URL] = []
        var cancelledImageURLs: [URL] = []
        
        var loadFeedCount: Int {
            return self.loadCompletions.count
        }
        
        func load(completion: @escaping (FeedLoader.Result) -> ()) {
            self.loadCompletions.append(completion)
        }
        
        func completeLoad(with result: FeedLoader.Result, at index: Int = 0) {
            self.loadCompletions[index](result)
        }
        
        func loadImageData(from url: URL) {
            self.loadedImageURLs.append(url)
        }
        
        func cancelImageDataLoad(from url: URL) {
            self.cancelledImageURLs.append(url)
        }
    }
}
