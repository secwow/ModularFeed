import Foundation
import FeedFramework

public final class FeedUIComposer {
    private init() {}
    
    public static func feedComposedWith(feedLoader: FeedLoader, imageLoader: FeedImageDataLoader) -> FeedViewController {
        let refreshController = FeedRefreshViewController(with: feedLoader)
        let vc = FeedViewController(refreshController: refreshController)
        refreshController.onRefresh = adaptFeedToCellViewControllers(forwarding: vc, loader: imageLoader)
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
