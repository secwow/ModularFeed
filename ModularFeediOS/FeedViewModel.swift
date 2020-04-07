import FeedFramework

final class FeedViewModel {
    private let feedLoader: FeedLoader
    typealias Observer<T> = (T) -> Void
    
    init(with feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }
        
    var onLoadingStateChanged: Observer<Bool>?
    var onFeedLoad: Observer<[FeedImage]>?
    
    func loadFeed() {
        self.onLoadingStateChanged?(true)
        self.feedLoader.load(completion: { [weak self] result in
            if let feed = try? result.get() {
                self?.onFeedLoad?(feed)
            }
            
            self?.onLoadingStateChanged?(false)
        })
    }
}
