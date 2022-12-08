//  Created by Marcell Magyar on 07.12.22.

import UIKit

public final class MoviesViewController: UITableViewController {
    private var refreshController: MoviesRefreshController?
    
    var cellControllers = [MovieCellController]() {
        didSet { tableView.reloadData() }
    }
    
    convenience init(refreshController: MoviesRefreshController) {
        self.init()
        self.refreshController = refreshController
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(MovieCell.self)
        
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
}
