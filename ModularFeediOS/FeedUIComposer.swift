import Foundation
import FeedFramework

public final class FeedUIComposer {
    private init() {}
    
    public static func feedComposedWith(feedLoader: FeedLoader, imageLoader: FeedImageDataLoader) -> FeedViewController {
        let feedViewModel = FeedViewModel(with: feedLoader)
        let refreshController = FeedRefreshViewController(with: feedViewModel)
        let vc = FeedViewController(refreshController: refreshController)
        feedViewModel.onFeedLoad = adaptFeedToCellViewControllers(forwarding: vc, loader: imageLoader)

        return vc
    }
    
    private static func adaptFeedToCellViewControllers(forwarding controller: FeedViewController, loader: FeedImageDataLoader) -> ([FeedImage]) -> Void {
        return { [weak controller] feed in
            controller?.tableModel = feed.map { (model) in
                FeedImageCellController(with: model, imageLoader: loader)
            }
        }
    }
}
