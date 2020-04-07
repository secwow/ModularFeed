import UIKit

public final class FeedViewController: UITableViewController, UITableViewDataSourcePrefetching {
    
    private var refreshController: FeedRefreshViewController?
    var tableModel: [FeedImageCellController] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    convenience init(refreshController: FeedRefreshViewController) {
        self.init()
        self.refreshController = refreshController
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        tableView.prefetchDataSource = self
        refreshControl = self.refreshController?.view
        
        refreshController?.refresh()
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableModel.count
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cellControllerForRow(at: indexPath).view()
    }
    
    public override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        self.removeCellController(for: indexPath)
    }
    
    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { (indexPath) in
            cellControllerForRow(at: indexPath).preload()
        }
    }
    
    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach(removeCellController)
    }
    
    private func cellControllerForRow(at indexPath: IndexPath) -> FeedImageCellController {
        return tableModel[indexPath.row]
    }
    
    private func removeCellController(for indexPath: IndexPath) {
        self.tableModel[indexPath.row].cancelLoad()
    }
}
