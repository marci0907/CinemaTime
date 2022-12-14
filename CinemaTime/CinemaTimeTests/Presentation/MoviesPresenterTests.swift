//  Created by Marcell Magyar on 14.12.22.

import XCTest
import CinemaTime

final class MoviesPresenterTests: XCTestCase {
    
    func test_init_doesNotRequestMovieLoadingFromLoader() {
        let view = ViewSpy()
        let loader = LoaderSpy()
        _ = MoviesPresenter(moviesView: view, loadingView: view, loader: loader)
        
        XCTAssertTrue(view.receivedMessages.isEmpty)
        XCTAssertTrue(loader.receivedMovieLoads.isEmpty)
    }
    
    func test_load_startsLoading() {
        let view = ViewSpy()
        let sut = MoviesPresenter(moviesView: view, loadingView: view, loader: LoaderSpy())
        
        sut.load()
        
        XCTAssertEqual(view.receivedMessages, [.display(isLoading: true)])
    }
    
    // MARK: -
    
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
