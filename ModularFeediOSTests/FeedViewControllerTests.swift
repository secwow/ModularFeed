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
    
    func test_feedImageView_dismissLoadingIndicatorWhenImageIsLoaded() {
        let (sut, loader) = makeSUT()
        let image = makeImage(url: URL(string: "http://url-1.com")!)
        let image2 = makeImage(url: URL(string: "http://url-2.com")!)
        
        sut.loadViewIfNeeded()
        loader.completeLoad(with: .success([image, image2]), at: 0)
        let view0 = sut.simulateImageFeedViewVisible(at: 0)
        let view1 = sut.simulateImageFeedViewVisible(at: 1)
        XCTAssertEqual(view0?.isShowingImageLoadingIndicator, true)
        XCTAssertEqual(view1?.isShowingImageLoadingIndicator, true)
        
        loader.completeImageLoading(at: 0)
        XCTAssertEqual(view0?.isShowingImageLoadingIndicator, false)
        XCTAssertEqual(view1?.isShowingImageLoadingIndicator, true)
        
        loader.completeImageLoadingWithError(at: 1)
        XCTAssertEqual(view0?.isShowingImageLoadingIndicator, false)
        XCTAssertEqual(view1?.isShowingImageLoadingIndicator, false)
    }
    
    func test_feedImageView_rendersImageLoadedFromURL() {
        let (sut, loader) = makeSUT()
        let image = makeImage()
        let image2 = makeImage()
        
        sut.loadViewIfNeeded()
        loader.completeLoad(with: .success([image, image2]), at: 0)
        let view0 = sut.simulateImageFeedViewVisible(at: 0)
        let view1 = sut.simulateImageFeedViewVisible(at: 1)
        XCTAssertEqual(view0?.renderedImage, .none)
        XCTAssertEqual(view1?.renderedImage, .none)
        
        let imageData0 = UIImage.make(withColor: .blue).pngData()!
        loader.completeImageLoading(with:imageData0, at: 0)
        XCTAssertEqual(view0?.renderedImage, imageData0)
        XCTAssertEqual(view1?.renderedImage, .none)
        
        let imageData1 = UIImage.make(withColor: .red).pngData()!
        loader.completeImageLoading(with:imageData1, at: 1)
        XCTAssertEqual(view0?.renderedImage, imageData0)
        XCTAssertEqual(view1?.renderedImage, imageData1)
    }
    
    func test_feedImageViewRetryButton_isVisibleOnImageURLLoadError() {
        let (sut, loader) = makeSUT()
        let image = makeImage()
        let image2 = makeImage()
        
        sut.loadViewIfNeeded()
        loader.completeLoad(with: .success([image, image2]), at: 0)
        let view0 = sut.simulateImageFeedViewVisible(at: 0)
        let view1 = sut.simulateImageFeedViewVisible(at: 1)
        XCTAssertEqual(view0?.isShowingRetryAction, false)
        XCTAssertEqual(view1?.isShowingRetryAction, false)
        
        let imageData0 = UIImage.make(withColor: .blue).pngData()!
        loader.completeImageLoading(with:imageData0, at: 0)
        XCTAssertEqual(view0?.isShowingRetryAction, false)
        XCTAssertEqual(view1?.isShowingRetryAction, false)
        
        loader.completeImageLoadingWithError(at: 1)
        XCTAssertEqual(view0?.isShowingRetryAction, false)
        XCTAssertEqual(view1?.isShowingRetryAction, true)
    }
    
    func test_feedImageViewRetryButton_isVisibleOnInvalidImageData() {
        let (sut, loader) = makeSUT()
        let image = makeImage()
        let image2 = makeImage()
        
        sut.loadViewIfNeeded()
        loader.completeLoad(with: .success([image, image2]), at: 0)
        let view0 = sut.simulateImageFeedViewVisible(at: 0)
        
        let imageData0 = "let imageData0 = UIImage.make(withColor: .blue).pngData()!".data(using: .utf8)!
        loader.completeImageLoading(with:imageData0, at: 0)
        XCTAssertEqual(view0?.isShowingRetryAction, true)
    }
    
    func test_feedImageViewRetryAction_retriesImageLoad() {
        let (sut, loader) = makeSUT()
        let image = makeImage()
        let image2 = makeImage()
        
        sut.loadViewIfNeeded()
        loader.completeLoad(with: .success([image, image2]), at: 0)
        let view0 = sut.simulateImageFeedViewVisible(at: 0)
        let view1 = sut.simulateImageFeedViewVisible(at: 1)
        XCTAssertEqual(loader.loadedImageURLs, [image.url, image2.url])
        
        loader.completeImageLoadingWithError(at: 0)
        loader.completeImageLoadingWithError(at: 1)
        XCTAssertEqual(loader.loadedImageURLs, [image.url, image2.url])
        
        view0?.simulateRetryAction()
        XCTAssertEqual(loader.loadedImageURLs, [image.url, image2.url, image.url])
        
        view1?.simulateRetryAction()
        XCTAssertEqual(loader.loadedImageURLs,  [image.url, image2.url, image.url, image2.url])
    }
    
    func test_feedImageView_preloadsImageURLWhenNearVisible() {
        let (sut, loader) = makeSUT()
        let image = makeImage()
        let image2 = makeImage()
        
        sut.loadViewIfNeeded()
        loader.completeLoad(with: .success([image, image2]), at: 0)
        XCTAssertEqual(loader.loadedImageURLs, [])
        
        sut.simulateFeedImageViewNearVisible(at: 0)
        XCTAssertEqual(loader.loadedImageURLs, [image.url])
        
        sut.simulateFeedImageViewNearVisible(at: 1)
        XCTAssertEqual(loader.loadedImageURLs, [image.url, image2.url])
    }
    
    func test_feedImageView_cancelImageLoadingWhenViewNotNearVisible() {
          let (sut, loader) = makeSUT()
        let image = makeImage()
        let image2 = makeImage()
        
        sut.loadViewIfNeeded()
        loader.completeLoad(with: .success([image, image2]), at: 0)
        XCTAssertEqual(loader.loadedImageURLs, [])
        
        sut.simulateFeedImageViewNotNearVisible(at: 0)
        XCTAssertEqual(loader.cancelledImageURLs, [image.url])
        
        sut.simulateFeedImageViewNotNearVisible(at: 1)
        XCTAssertEqual(loader.cancelledImageURLs, [image.url, image2.url])
    }
    
    func makeSUT(file: StaticString = #file, line: UInt = #line) -> (FeedViewController, LoaderSpy) {
        let loader = LoaderSpy()
        let sut = FeedUIComposer.feedComposedWith(feedLoader: loader, imageLoader: loader)
        trackForMemoryLeak(object: loader)
        trackForMemoryLeak(object: sut)
        return (sut, loader)
    }
    
    func makeImage(description: String? = nil, location: String? = nil, url: URL = URL(string: "http://someurl.com")!) -> FeedImage {
        return FeedImage(id: UUID(), description: description, location: location, url: url)
    }
}
