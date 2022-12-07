//  Created by Marcell Magyar on 07.12.22.

import XCTest
import UIKit
import CinemaTime

final class WeakRefProxy<T: AnyObject> {
    weak var object: T?
    
    init(_ object: T?) {
        self.object = object
    }
}

extension WeakRefProxy: MoviesView where T: MoviesView {
    func display(_ viewModel: MoviesViewModel) {
        object?.display(viewModel)
    }
}

final class MoviesUIComposer {
    private init() {}
    
    static func viewController(loader: MovieLoader) -> MoviesViewController {
        let refreshController = MoviesRefreshController()
        let viewController = MoviesViewController(refreshController: refreshController)
        let presenter = MoviesPresenter(moviesView: WeakRefProxy(viewController), loaderView: refreshController, loader: loader)
        refreshController.presenter = presenter
        return viewController
    }
}

final class MoviesPresenter {
    private let moviesView: MoviesView
    private let loaderView: MoviesLoaderView
    private let loader: MovieLoader
    
    init(moviesView: MoviesView, loaderView: MoviesLoaderView, loader: MovieLoader) {
        self.moviesView = moviesView
        self.loaderView = loaderView
        self.loader = loader
    }
    
    func load() {
        loaderView.display(MoviesLoadingViewModel(isLoading: true))
        loader.load { [weak self] result in
            self?.loaderView.display(MoviesLoadingViewModel(isLoading: false))
            if let movies = try? result.get() {
                self?.moviesView.display(MoviesViewModel(movies: movies))
            }
        }
    }
}

struct MoviesLoadingViewModel {
    let isLoading: Bool
}

protocol MoviesLoaderView {
    func display(_ viewModel: MoviesLoadingViewModel)
}

struct MoviesViewModel {
    let movies: [Movie]
}

protocol MoviesView {
    func display(_ viewModel: MoviesViewModel)
}

final class MoviesRefreshController: NSObject, MoviesLoaderView {
    var presenter: MoviesPresenter?
    
    lazy var view: UIRefreshControl = {
        let view = UIRefreshControl()
        view.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return view
    }()
    
    @objc
    func refresh() {
        presenter?.load()
    }
    
    func display(_ viewModel: MoviesLoadingViewModel) {
        if viewModel.isLoading {
            view.beginRefreshing()
        } else {
            view.endRefreshing()
        }
    }
}

final class MovieCell: UITableViewCell {
    let posterView = UIImageView()
    let titleLabel = UILabel()
    let ratingLabel = UILabel()
    let overviewLabel = UILabel()
}

final class MoviesViewController: UITableViewController {
    private var refreshController: MoviesRefreshController?
    
    var movies = [Movie]() {
        didSet { tableView.reloadData() }
    }
    
    convenience init(refreshController: MoviesRefreshController) {
        self.init()
        self.refreshController = refreshController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(MovieCell.self, forCellReuseIdentifier: "\(MovieCell.self)")
        
        refreshControl = refreshController?.view
        
        refreshController?.refresh()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movies.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let movie = movies[indexPath.row]
        
        guard let movieCell = tableView.dequeueReusableCell(withIdentifier: "\(MovieCell.self)") as? MovieCell else {
            return UITableViewCell()
        }
        
        movieCell.titleLabel.text = movie.title
        movieCell.overviewLabel.text = movie.overview
        movieCell.ratingLabel.text = String(describing: movie.rating)
        
        return movieCell
    }
}

extension MoviesViewController: MoviesView {
    func display(_ viewModel: MoviesViewModel) {
        movies = viewModel.movies
    }
}

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
        
        loader.completeMovieLoading(with: [])
        XCTAssertFalse(sut.isShowingLoadingIndicator)
        
        sut.triggerUserInitiatedRefresh()
        XCTAssertTrue(sut.isShowingLoadingIndicator)
        
        loader.completeMovieLoading(with: anyNSError())
        XCTAssertFalse(sut.isShowingLoadingIndicator)
    }
    
    func test_loaderCompletion_rendersZeroMoviesFromReceivedEmptyList() {
        let loader = LoaderSpy()
        let sut = makeSUT(with: loader)
        
        loader.completeMovieLoading(with: [])
        
        XCTAssertEqual(sut.renderedMoviesCount, 0)
    }
    
    func test_loaderCompletion_rendersMoviesFromReceivedList() {
        let movie1 = makeMovie(title: "first title", overview: "first overview", rating: 1)
        let movie2 = makeMovie(title: "second title", overview: "second overview", rating: 2)
        let loader = LoaderSpy()
        
        let sut = makeSUT(with: loader)
        assert(sut, isRendering: [])
        
        loader.completeMovieLoading(with: [movie2])
        assert(sut, isRendering: [movie2])
        
        sut.triggerUserInitiatedRefresh()
        
        loader.completeMovieLoading(with: [movie1, movie2])
        assert(sut, isRendering: [movie1, movie2])
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
        XCTAssertEqual(movieCell.ratingLabel.text, String(describing: movie.rating), file: file, line: line)
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
        
        func completeMovieLoading(with error: Error, at index: Int = 0) {
            receivedMessages[index](.failure(error))
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
