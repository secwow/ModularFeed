import UIKit
import FeedFramework

class FeedRefreshViewController: NSObject {
    private(set) lazy var view: UIRefreshControl = {
        let view = UIRefreshControl()
        view.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return view
    }()
    
    private let feedLoader: FeedLoader
    
    init(with feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }
    
    var onRefresh: (([FeedImage])->Void)?
    
    @objc func refresh() {
        view.beginRefreshing()
        self.feedLoader.load(completion: { [weak self] result in
            switch result {
            case let .success(feed):
                self?.onRefresh?(feed)
            default:
                break
            }
            self?.view.endRefreshing()
        })
    }
}
