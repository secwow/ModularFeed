import UIKit
import FeedFramework

public protocol FeedImageDataLoaderTask {
    func cancel()
}

public protocol FeedImageDataLoader {
    typealias Result = Swift.Result<Data, Error>
    
    func loadImageData(from url: URL, completion: @escaping(Result) -> ()) -> FeedImageDataLoaderTask
}

public final class FeedViewController: UITableViewController, UITableViewDataSourcePrefetching {
    
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
        tableView.prefetchDataSource = self
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
        cell.feedImageView.image = nil
        cell.feedImageRetryButton.isHidden = true
        cell.feedImageContainer.startShimmering()
        
        let loadImage = { [weak self, weak cell] in
            guard let self = self else { return }
            self.tasks[indexPath] = self.imageLoader?.loadImageData(from: model.url) { [weak cell] result in
                let data = try? result.get()
                let image =  data.map(UIImage.init) ?? nil
                cell?.feedImageView.image = image
                cell?.feedImageRetryButton.isHidden = (image != nil)
                cell?.feedImageContainer.stopShimmering()
            }
        }
        
        cell.onRetry = loadImage
        loadImage()
        
        return cell
    }
    
    public override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        self.cancelTask(for: indexPath)
    }
    
    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { (indexPath) in
            let cellModel = tableModel[indexPath.row]
            tasks[indexPath] = imageLoader?.loadImageData(from: cellModel.url, completion: { (result) in
            })
        }
    }
    
    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { (indexPath) in
            self.cancelTask(for: indexPath)
        }
    }
    
    private func cancelTask(for indexPath: IndexPath) {
        tasks[indexPath]?.cancel()
        tasks[indexPath] = nil
    }
}
