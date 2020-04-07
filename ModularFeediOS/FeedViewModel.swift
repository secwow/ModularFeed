import FeedFramework

final class FeedViewModel {
    private let feedLoader: FeedLoader
    
    init(with feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }
        
    var onChanged: ((FeedViewModel) -> ())?
    var onFeedLoad: (([FeedImage]) -> ())?
    
    private(set) var isLoading: Bool = false {
        didSet {
            self.onChanged?(self)
        }
    }
    
    func loadFeed() {
        self.isLoading = true
        self.feedLoader.load(completion: { [weak self] result in
            if let feed = try? result.get() {
                self?.onFeedLoad?(feed)
            }
            
            self?.isLoading = false
        })
    }
}
