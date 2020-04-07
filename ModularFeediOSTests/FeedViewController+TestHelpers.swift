import UIKit
import ModularFeediOS

extension FeedViewController {
    func simulatePullLoading() {
        refreshControl?.simulatePullToRefresh()
    }
    
    var isShownLoadingIndicator: Bool {
        return refreshControl?.isRefreshing == true
    }
    
    var numberRenderedFeedImageViews: Int {
        return tableView.numberOfRows(inSection: feedImageSection)
    }
    
    var feedImageSection: Int {
        return 0
    }
    
    func feedImageView(at: Int) -> UITableViewCell? {
        let ds = tableView.dataSource
        let index = IndexPath(row: at, section: 0)
        return ds?.tableView(tableView, cellForRowAt: index)
    }
    
    @discardableResult
    func simulateImageFeedViewVisible(at index: Int) -> FeedImageViewCell? {
        return feedImageView(at: index) as? FeedImageViewCell
    }
    
    func simulateFeedImageViewNotVisible(at row: Int) {
        let view = simulateImageFeedViewVisible(at: row)
        
        let delegate = tableView.delegate
        let index = IndexPath(row: row, section: feedImageSection)
        delegate?.tableView?(tableView, didEndDisplaying: view!, forRowAt: index)
    }
    
    func simulateFeedImageViewNearVisible(at row: Int) {
        let ds = tableView.prefetchDataSource
        let index = IndexPath(row: row, section: feedImageSection)
        ds?.tableView(tableView, prefetchRowsAt: [index])
    }
    
    func simulateFeedImageViewNotNearVisible(at row: Int) {
        simulateFeedImageViewNearVisible(at: row)
        
        let ds = tableView.prefetchDataSource
        let index = IndexPath(row: row, section: 0)
        ds?.tableView?(tableView, cancelPrefetchingForRowsAt: [index])
    }
}
