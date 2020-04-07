import UIKit

final class FeedRefreshViewController: NSObject {
    private(set) lazy var view = binded(UIRefreshControl())
    
    private let viewModel: FeedViewModel
    
    init(with viewModel: FeedViewModel) {
        self.viewModel = viewModel
    }
    
    private func binded(_ view: UIRefreshControl) -> UIRefreshControl {
        viewModel.onChanged = { [weak self] viewModel in
            if viewModel.isLoading {
                self?.view.beginRefreshing()
               
            } else {
                self?.view.endRefreshing()
            }
        }
        
        view.addTarget(self, action: #selector(refresh), for: .valueChanged)
        
        return view
    }
    
    @objc func refresh() {
        viewModel.loadFeed()
    }
}
