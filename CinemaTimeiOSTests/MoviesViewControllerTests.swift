//  Created by Marcell Magyar on 07.12.22.

import XCTest
import UIKit

final class MoviesViewController: UITableViewController {
    
}

final class MoviesViewControllerTests: XCTestCase {
    
    func test_init_doesNotRenderMovies() {
        let sut = MoviesViewController()
        
        XCTAssertEqual(sut.renderedMovies, 0)
    }
}

private extension MoviesViewController {
    var renderedMovies: Int {
        let ds = tableView.dataSource!
        return ds.tableView(tableView, numberOfRowsInSection: 0)
    }
}
