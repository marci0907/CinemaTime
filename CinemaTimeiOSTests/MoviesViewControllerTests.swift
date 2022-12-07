//  Created by Marcell Magyar on 07.12.22.

import XCTest
import UIKit
import CinemaTime
import CinemaTimeiOS

final class MoviesViewControllerTests: XCTestCase {
    
    func test_userInitiatedRefresh_triggersMovieLoading() {
        let loader = LoaderSpy()
        let sut = makeSUT(with: loader)
        XCTAssertEqual(loader.receivedMessages.count, 1)
        
        sut.triggerUserInitiatedRefresh()
        XCTAssertEqual(loader.receivedMessages.count, 2)
        
        sut.triggerUserInitiatedRefresh()
        XCTAssertEqual(loader.receivedMessages.count, 3)
    }
    
    func test_loaderCompletion_stopsRefreshing() {
        let loader = LoaderSpy()
        let sut = makeSUT(with: loader)
        XCTAssertTrue(sut.isShowingLoadingIndicator)
        
        loader.completeMovieLoading(with: [], at: 0)
        XCTAssertFalse(sut.isShowingLoadingIndicator)
        
        sut.triggerUserInitiatedRefresh()
        XCTAssertTrue(sut.isShowingLoadingIndicator)
        
        loader.completeMovieLoadingWithError(at: 1)
        XCTAssertFalse(sut.isShowingLoadingIndicator)
    }
    
    func test_loaderCompletion_rendersMoviesFromReceivedList() {
        let movie1 = makeMovie(title: "first title", overview: "first overview", rating: 1)
        let movie2 = makeMovie(title: "second title", overview: "second overview", rating: 2)
        let loader = LoaderSpy()
        
        let sut = makeSUT(with: loader)
        assert(sut, isRendering: [])
        
        loader.completeMovieLoading(with: [movie2], at: 0)
        assert(sut, isRendering: [movie2])
        
        sut.triggerUserInitiatedRefresh()
        
        loader.completeMovieLoading(with: [movie1, movie2], at: 1)
        assert(sut, isRendering: [movie1, movie2])
    }
    
    func test_loaderCompletion_rendersZeroMoviesAfterRenderingNonEmptyMovies() {
        let movie1 = makeMovie(title: "first title", overview: "first overview", rating: 1)
        let movie2 = makeMovie(title: "second title", overview: "second overview", rating: 2)
        let loader = LoaderSpy()
        
        let sut = makeSUT(with: loader)
        
        loader.completeMovieLoading(with: [movie1, movie2], at: 0)
        assert(sut, isRendering: [movie1, movie2])
        
        sut.triggerUserInitiatedRefresh()
        
        loader.completeMovieLoading(with: [], at: 1)
        assert(sut, isRendering: [])
    }
    
    // MARK: - Helpers
    
    private func makeSUT(with loader: MovieLoader = LoaderSpy(), file: StaticString = #file, line: UInt = #line) -> MoviesViewController {
        let sut = MoviesUIComposer.viewController(loader: loader)
        sut.loadViewIfNeeded()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func assert(_ sut: MoviesViewController, isRendering movies: [Movie], file: StaticString = #file, line: UInt = #line) {
        guard sut.renderedMoviesCount == movies.count else {
            return XCTFail("Expected rendering \(movies.count) movies, rendering \(sut.renderedMoviesCount) instead", file: file, line: line)
        }
        
        movies.enumerated().forEach { index, movie in
            assert(sut, hasViewConfiguredFor: movie, at: index, file: file, line: line)
        }
    }
    
    private func assert(_ sut: MoviesViewController, hasViewConfiguredFor movie: Movie, at index: Int, file: StaticString = #file, line: UInt = #line) {
        let cell = sut.renderedMovie(at: index)
        
        guard let movieCell = cell as? MovieCell else {
            return XCTFail("Expected \(MovieCell.self), found \(String(describing: cell)) instead", file: file, line: line)
        }
        
        XCTAssertEqual(movieCell.titleLabel.text, movie.title, file: file, line: line)
        XCTAssertEqual(movieCell.ratingLabel.text, "\(movie.rating ?? 0.0)", file: file, line: line)
        XCTAssertEqual(movieCell.overviewLabel.text, movie.overview, file: file, line: line)
    }
    
    private func makeMovie(title: String, overview: String, rating: Double) -> Movie {
        Movie(id: 0, title: title, imagePath: nil, overview: overview, releaseDate: nil, rating: rating)
    }
    
    private func anyNSError() -> Error {
        NSError(domain: "a domain", code: 0)
    }
    
    private class LoaderSpy: MovieLoader {
        typealias Message = (MovieLoader.Result) -> Void
        
        private(set) var receivedMessages = [Message]()
        
        func load(completion: @escaping Message) {
            receivedMessages.append(completion)
        }
        
        func completeMovieLoading(with movies: [Movie], at index: Int = 0) {
            receivedMessages[index](.success(movies))
        }
        
        func completeMovieLoadingWithError(at index: Int = 0) {
            receivedMessages[index](.failure(NSError(domain: "a domain", code: 0)))
        }
    }
}

private extension MoviesViewController {
    var renderedMoviesCount: Int {
        let ds = tableView.dataSource!
        return ds.tableView(tableView, numberOfRowsInSection: 0)
    }
    
    func renderedMovie(at index: Int) -> UITableViewCell? {
        let ds = tableView.dataSource
        return ds?.tableView(tableView, cellForRowAt: IndexPath(row: index, section: 0))
    }
    
    var isShowingLoadingIndicator: Bool {
        return refreshControl?.isRefreshing ?? false
    }
    
    func triggerUserInitiatedRefresh() {
        refreshControl?.triggerRefresh()
    }
}

private extension UIRefreshControl {
    func triggerRefresh() {
        allTargets.forEach { target in
            actions(forTarget: target, forControlEvent: .valueChanged)?.forEach { action in
                (target as NSObject).perform(Selector(action))
            }
        }
    }
}
