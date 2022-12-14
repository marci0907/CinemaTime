//  Created by Marcell Magyar on 14.12.22.

import XCTest
import CinemaTime

final class MoviesPresenterTests: XCTestCase {
    
    func test_title_isLocalized() {
        XCTAssertEqual(MoviesPresenter.title, localized("NOW_PLAYING_MOVIES_TITLE"))
    }
    
    func test_init_doesNotRequestMovieLoadingFromLoader() {
        let (_, view, loader) = makeSUT()
        
        XCTAssertTrue(view.receivedMessages.isEmpty)
        XCTAssertTrue(loader.receivedMovieLoads.isEmpty)
    }
    
    func test_load_startsLoadingAndRequestsMovieLoadingFromLoader() {
        let (sut, view, loader) = makeSUT()
        
        sut.load()
        
        XCTAssertEqual(view.receivedMessages, [.display(isLoading: true)])
        XCTAssertEqual(loader.receivedMovieLoads.count, 1)
    }
    
    func test_loaderCompletion_stopsLoadingOnError() {
        let (sut, view, loader) = makeSUT()
        sut.load()
        
        loader.completeMovieLoadingWithError()
        
        XCTAssertEqual(view.receivedMessages, [
            .display(isLoading: true),
            .display(isLoading: false)
        ])
    }
    
    func test_loaderCompletion_stopsLoadingAndDisplaysZeroMoviesOnEmptyList() {
        let (sut, view, loader) = makeSUT()
        sut.load()
        
        loader.completeMovieLoading(with: [])
        
        XCTAssertEqual(view.receivedMessages, [
            .display(isLoading: true),
            .display(isLoading: false),
            .display(movies: [])
        ])
    }
    
    func test_loaderCompletion_stopsLoadingAndDisplaysReceivedMovies() {
        let movies = [makeMovie(title: "first"), makeMovie(title: "second"), makeMovie(title: "third")]
        let (sut, view, loader) = makeSUT()
        sut.load()
        
        loader.completeMovieLoading(with: movies)
        
        XCTAssertEqual(view.receivedMessages, [
            .display(isLoading: true),
            .display(isLoading: false),
            .display(movies: movies)
        ])
    }
    
    // MARK: -
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (MoviesPresenter, ViewSpy, LoaderSpy) {
        let view = ViewSpy()
        let loader = LoaderSpy()
        let sut = MoviesPresenter(moviesView: view, loadingView: view, loader: loader)
        trackForMemoryLeaks(view, file: file, line: line)
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, view, loader)
    }
    
    private func localized(_ key: String, file: StaticString = #file, line: UInt = #line) -> String {
        let table = "Movies"
        let bundle = Bundle(for: MoviesPresenter.self)
        let localizedString = bundle.localizedString(forKey: key, value: nil, table: table)
        if localizedString == key {
            XCTFail("Localized string for key \(key) in table \(table) not found", file: file, line: line)
        }
        return localizedString
    }
    
    func makeMovie(
        title: String = "any title",
        imagePath: String? = "/any.jpg",
        overview: String = "any overview",
        releaseDate: Date? = nil,
        rating: Double = 1.0
    ) -> Movie {
        Movie(id: 0, title: title, imagePath: imagePath, overview: overview, releaseDate: releaseDate, rating: rating)
    }
    
    private class LoaderSpy: MovieLoader {
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
    }
    
    private class ViewSpy: MoviesView, MoviesLoadingView {
        enum Message: Equatable {
            case display(movies: [Movie])
            case display(isLoading: Bool)
        }
        
        private(set) var receivedMessages = [Message]()
        
        func display(_ viewModel: MoviesViewModel) {
            receivedMessages.append(.display(movies: viewModel.movies))
        }
        
        func display(_ viewModel: MoviesLoadingViewModel) {
            receivedMessages.append(.display(isLoading: viewModel.isLoading))
        }
    }
}
