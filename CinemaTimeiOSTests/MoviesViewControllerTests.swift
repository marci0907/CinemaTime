//  Created by Marcell Magyar on 07.12.22.

import XCTest
import UIKit
import CinemaTime
import CinemaTimeiOS

final class MoviesViewControllerTests: XCTestCase {
    
    func test_userInitiatedRefresh_triggersMovieLoading() {
        let (sut, loader) = makeSUT()
        XCTAssertEqual(loader.receivedMovieLoads.count, 1)
        
        sut.triggerUserInitiatedRefresh()
        XCTAssertEqual(loader.receivedMovieLoads.count, 2)
        
        sut.triggerUserInitiatedRefresh()
        XCTAssertEqual(loader.receivedMovieLoads.count, 3)
    }
    
    func test_loaderCompletion_stopsRefreshing() {
        let (sut, loader) = makeSUT()
        XCTAssertTrue(sut.isShowingLoadingIndicator)
        
        loader.completeMovieLoading(with: [], at: 0)
        XCTAssertFalse(sut.isShowingLoadingIndicator)
        
        sut.triggerUserInitiatedRefresh()
        XCTAssertTrue(sut.isShowingLoadingIndicator)
        
        loader.completeMovieLoadingWithError(at: 1)
        XCTAssertFalse(sut.isShowingLoadingIndicator)
    }
    
    // TODO: Tests for error case
    // test_loaderCompletion_displaysErrorViewOnLoaderError
    
    func test_loaderCompletion_rendersMoviesFromReceivedList() {
        let movie1 = makeMovie(title: "first title", overview: "first overview", rating: 1)
        let movie2 = makeMovie(title: "second title", overview: "second overview", rating: 2)
        let (sut, loader) = makeSUT()
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
        let (sut, loader) = makeSUT()
        
        loader.completeMovieLoading(with: [movie1, movie2], at: 0)
        assert(sut, isRendering: [movie1, movie2])
        
        sut.triggerUserInitiatedRefresh()
        loader.completeMovieLoading(with: [], at: 1)
        assert(sut, isRendering: [])
    }
    
    func test_loaderError_doesNotAlterPreviouslyLoadedMovies() {
        let movie1 = makeMovie(title: "first title", overview: "first overview", rating: 1)
        let movie2 = makeMovie(title: "second title", overview: "second overview", rating: 2)
        let (sut, loader) = makeSUT()
        
        loader.completeMovieLoading(with: [movie1, movie2], at: 0)
        assert(sut, isRendering: [movie1, movie2])
        
        sut.triggerUserInitiatedRefresh()
        loader.completeMovieLoadingWithError(at: 1)
        assert(sut, isRendering: [movie1, movie2])
    }
    
    func test_loadCompletion_triggersImageLoading() {
        let movie1 = makeMovie(title: "first title", imagePath: "/first", overview: "first overview", rating: 1)
        let movie2 = makeMovie(title: "second title", imagePath: "/second", overview: "second overview", rating: 2)
        let (sut, loader) = makeSUT()
        
        loader.completeMovieLoading(with: [movie1, movie2])
        
        sut.simulateVisibleMovieCell(at: 0)
        XCTAssertEqual(loader.receivedImagePaths, ["/first"])
        
        sut.simulateVisibleMovieCell(at: 1)
        XCTAssertEqual(loader.receivedImagePaths, ["/first", "/second"])
    }
    
    func test_movieCellRetryButton_isVisibleOnImageLoaderError() {
        let movie = makeMovie(title: "first title", imagePath: "/first", overview: "first overview", rating: 1)
        let (sut, loader) = makeSUT()
        loader.completeMovieLoading(with: [movie])
        
        sut.simulateVisibleMovieCell(at: 0)
        loader.completeImageLoading(with: anyNSError(), at: 0)
        
        XCTAssertTrue(sut.isRetryButtonVisible(at: 0))
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (MoviesViewController, LoaderSpy) {
        let loader = LoaderSpy()
        let sut = MoviesUIComposer.viewController(movieLoader: loader, imageLoader: loader)
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        sut.loadViewIfNeeded()
        return (sut, loader)
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
    
    private func makeMovie(title: String, imagePath: String? = nil, overview: String, rating: Double) -> Movie {
        Movie(id: 0, title: title, imagePath: imagePath, overview: overview, releaseDate: nil, rating: rating)
    }
    
    private func anyNSError() -> Error {
        NSError(domain: "a domain", code: 0)
    }
    
    private class LoaderSpy: MovieLoader, MovieImageDataLoader {
        
        // MARK: MovieLoader
        
        typealias Message = (MovieLoader.Result) -> Void
        
        private(set) var receivedMovieLoads = [Message]()
        
        func load(completion: @escaping (MovieLoader.Result) -> Void) {
            receivedMovieLoads.append(completion)
        }
        
        func completeMovieLoading(with movies: [Movie], at index: Int = 0) {
            receivedMovieLoads[index](.success(movies))
        }
        
        func completeMovieLoadingWithError(at index: Int = 0) {
            receivedMovieLoads[index](.failure(NSError(domain: "a domain", code: 0)))
        }
        
        // MARK: MovieImageDataLoader
        
        typealias ImageMessage = (imagePath: String?, completion: (MovieImageDataLoader.Result) -> Void)
        
        private(set) var receivedImageLoads = [ImageMessage]()
        var receivedImagePaths: [String?] {
            receivedImageLoads.map { $0.imagePath }
        }
        
        func load(from imagePath: String?, completion: @escaping (MovieImageDataLoader.Result) -> Void) -> MovieImageDataLoaderTask {
            receivedImageLoads.append((imagePath, completion))
            return Task()
        }
        
        func completeImageLoading(with error: Error, at index: Int = 0) {
            receivedImageLoads[index].completion(.failure(error))
        }
        
        private struct Task: MovieImageDataLoaderTask {
            func cancel() {}
        }
    }
}

private extension MoviesViewController {
    var renderedMoviesCount: Int {
        let ds = tableView.dataSource!
        return ds.tableView(tableView, numberOfRowsInSection: 0)
    }
    
    func renderedMovie(at row: Int) -> UITableViewCell? {
        let ds = tableView.dataSource
        return ds?.tableView(tableView, cellForRowAt: IndexPath(row: row, section: 0))
    }
    
    func simulateVisibleMovieCell(at row: Int) {
        let ds = tableView.dataSource
        _ = ds?.tableView(tableView, cellForRowAt: IndexPath(row: row, section: 0))
    }
    
    var isShowingLoadingIndicator: Bool {
        return refreshControl?.isRefreshing ?? false
    }
    
    func triggerUserInitiatedRefresh() {
        refreshControl?.triggerRefresh()
    }
    
    func isRetryButtonVisible(at row: Int) -> Bool {
        guard let movieCell = renderedMovie(at: row) as? MovieCell else { return false }
        
        return !movieCell.retryButton.isHidden
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
