//  Created by Marcell Magyar on 07.12.22.

import UIKit

public final class MoviesViewController: UITableViewController {
    private var refreshController: MoviesRefreshController?
    
    public var cellControllers = [MovieCellController]() {
        didSet { tableView.reloadData() }
    }
    
    public convenience init(refreshController: MoviesRefreshController) {
        self.init()
        self.refreshController = refreshController
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(MovieCell.self)
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        
        refreshControl = refreshController?.view
        refreshController?.refresh()
    }
    
    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        cellControllers.count
    }
    
    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        cellControllers[indexPath.row].view(in: tableView)
    }
    
    public override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellControllers[indexPath.row].cancelImageLoading()
    }
    
    public override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellControllers[indexPath.row].preloadImageData(for: cell)
    }
}
