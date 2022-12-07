//  Created by Marcell Magyar on 07.12.22.

import XCTest
import UIKit

final class MoviesViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl = UIRefreshControl()
        refreshControl?.beginRefreshing()
    }
}

final class MoviesViewControllerTests: XCTestCase {
    
    func test_init_doesNotRenderMovies() {
        let sut = MoviesViewController()
        
        XCTAssertEqual(sut.renderedMovies, 0)
    }
    
    func test_viewDidLoad_startsLoadingMovies() {
        let sut = MoviesViewController()
        
        sut.loadViewIfNeeded()
        
        XCTAssertTrue(sut.isLoading)
    }
}

private extension MoviesViewController {
    var renderedMovies: Int {
        let ds = tableView.dataSource!
        return ds.tableView(tableView, numberOfRowsInSection: 0)
    }
    
    var isLoading: Bool {
        return refreshControl?.isRefreshing ?? false
    }
}
