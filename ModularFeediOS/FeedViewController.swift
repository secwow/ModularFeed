import UIKit
import FeedFramework

public protocol FeedImageDataLoaderTask {
    func cancel()
}

public protocol FeedImageDataLoader {
    func loadImageData(from url: URL) -> FeedImageDataLoaderTask
}

public final class FeedViewController: UITableViewController {
    
    private var feedLoader: FeedLoader?
    private var tableModel: [FeedImage] = []
    private var imageLoader: FeedImageDataLoader?
    private var tasks: [IndexPath: FeedImageDataLoaderTask] = [:]
    
    public convenience init(loader: FeedLoader, imageLoader: FeedImageDataLoader) {
        self.init()
        self.feedLoader = loader
        self.imageLoader = imageLoader
    }
    
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(load), for: .valueChanged)
        load()
    }
    
    
    @objc func load() {
        self.refreshControl?.beginRefreshing()
        self.feedLoader?.load(completion: { [weak self] result in
            switch result {
            case let .success(feed):
                self?.tableModel = feed
                self?.tableView.reloadData()
            case let .failure(error):
                break
            }
            self?.refreshControl?.endRefreshing()
            
        })
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableModel.count
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = tableModel[indexPath.row]
        
        let cell = FeedImageViewCell()
        cell.descriptionLabel.text = model.description
        cell.locationLabel.text = model.location
        cell.locationContainer.isHidden = (model.location == nil)
        
        tasks[indexPath] = imageLoader?.loadImageData(from: model.url)
        return cell
    }
    
    public override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        tasks[indexPath]?.cancel()
        tasks[indexPath] = nil
    }
}