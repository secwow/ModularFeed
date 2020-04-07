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
    
    private struct TaskSpy: FeedImageDataLoaderTask {
        let cancelCallback: () -> Void
        
        func cancel() {
            cancelCallback()
        }
    }
    
    class LoaderSpy: FeedLoader, FeedImageDataLoader {
        private var imageRequests = [(url: URL, completion:((FeedImageDataLoader.Result) -> ()))]()
        private var loadCompletions = [(FeedLoader.Result) -> ()]()
        
        var loadedImageURLs: [URL]  {
            return imageRequests.map({ $0.url })
        }
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
        
        func completeImageLoading(with imageData: Data = Data(), at index: Int) {
            imageRequests[index].completion(.success(imageData))
        }
        
        func completeImageLoadingWithError(at index: Int) {
            imageRequests[index].completion(.failure(anyNSError()))
        }
        
        func loadImageData(from url: URL, completion: @escaping (FeedImageDataLoader.Result) -> ()) -> FeedImageDataLoaderTask {
            self.imageRequests.append((url, completion))
            return TaskSpy { [weak self] in self?.cancelledImageURLs.append(url) }
        }
    }
}

private extension UIImage {
    static func make(withColor color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(color.cgColor)
        context.fill(rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }
}
