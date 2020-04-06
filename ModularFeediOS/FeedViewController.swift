import UIKit
import FeedFramework

public final class FeedViewController: UITableViewController {
    
    private var loader: FeedLoader?
    private var tableModel: [FeedImage] = []
    
    public convenience init(loader: FeedLoader) {
        self.init()
        self.loader = loader
    }
    
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(load), for: .valueChanged)
        refreshControl?.beginRefreshing()
        
        load()
    }
    
    
    @objc func load() {
        self.loader?.load(completion: { [weak self] result in
            switch result {
            case let .success(feed):
                self?.tableModel = (try? result.get()) ?? []
                self?.tableView.reloadData()
                self?.refreshControl?.endRefreshing()
            case let .failure(error):
                break
            }
            
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
        return cell
    }
}
