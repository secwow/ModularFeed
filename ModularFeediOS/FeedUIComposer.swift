import Foundation
import FeedFramework

public final class FeedUIComposer {
    private init() {}
    
    public static func feedComposedWith(feedLoader: FeedLoader, imageLoader: FeedImageDataLoader) -> FeedViewController {
        let refreshController = FeedRefreshViewController(with: feedLoader)
        let vc = FeedViewController(refreshController: refreshController)
        refreshController.onRefresh = { [weak vc] result in
            vc?.tableModel = result.map { (model) in
                FeedImageCellController(with: model, imageLoader: imageLoader)
            }
        }
        
        return vc
    }
}
