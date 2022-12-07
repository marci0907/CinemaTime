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
        let sut = makeSUT()
        
        XCTAssertEqual(sut.renderedMovies, 0)
    }
    
    func test_viewDidLoad_startsLoadingMovies() {
        let sut = makeSUT()
        
        sut.loadViewIfNeeded()
        
        XCTAssertTrue(sut.isLoading)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> MoviesViewController {
        let sut = MoviesViewController()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
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
