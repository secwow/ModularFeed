import Foundation
import FeedFramework
import ModularFeediOS

class LoaderSpy: FeedLoader, FeedImageDataLoader {
    private struct TaskSpy: FeedImageDataLoaderTask {
        let cancelCallback: () -> Void
        
        func cancel() {
            cancelCallback()
        }
    }
    
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
