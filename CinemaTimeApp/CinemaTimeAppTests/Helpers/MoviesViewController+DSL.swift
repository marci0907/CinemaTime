//  Created by Marcell Magyar on 13.12.22.

import UIKit
import CinemaTimeiOS

extension MoviesViewController {
    var renderedMoviesCount: Int {
        let ds = tableView.dataSource!
        return ds.tableView(tableView, numberOfRowsInSection: 0)
    }
    
    func renderedMovie(at row: Int) -> UITableViewCell? {
        let ds = tableView.dataSource
        return ds?.tableView(tableView, cellForRowAt: IndexPath(row: row, section: 0))
    }
    
    func renderedMovieData(at row: Int) -> Data? {
        let ds = tableView.dataSource
        let cell = ds?.tableView(tableView, cellForRowAt: IndexPath(row: row, section: 0)) as? MovieCell
        return cell?.renderedImageData
    }
    
    @discardableResult
    func simulateVisibleMovieCell(at row: Int) -> MovieCell? {
        let ds = tableView.dataSource
        return ds?.tableView(tableView, cellForRowAt: IndexPath(row: row, section: 0)) as? MovieCell
    }
    
    func simulateNearVisibleMovieCell(at row: Int) {
        let cell = tableView.dequeueReusableCell(withIdentifier: "\(MovieCell.self)", for: IndexPath(row: row, section: 0))
        let delegate = tableView.delegate
        delegate?.tableView?(tableView, willDisplay: cell, forRowAt: IndexPath(row: row, section: 0))
    }
    
    func simulateNotVisibleMovieCell(_ cell: UITableViewCell, at row: Int) {
        tableView.delegate?.tableView?(tableView, didEndDisplaying: cell, forRowAt: IndexPath(row: row, section: 0))
    }
    
    var isShowingLoadingIndicator: Bool {
        return refreshControl?.isRefreshing ?? false
    }
    
    func triggerUserInitiatedRefresh() {
        refreshControl?.triggerRefresh()
    }
}
