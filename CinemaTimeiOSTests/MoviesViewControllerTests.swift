//  Created by Marcell Magyar on 07.12.22.

import XCTest
import UIKit
import CinemaTime

final class MoviesUIComposer {
    private init() {}
    
    static func viewController(loader: MovieLoader) -> MoviesViewController {
        let refreshController = MoviesRefreshController()
        let presenter = MoviesPresenter(loaderView: refreshController, loader: loader)
        refreshController.presenter = presenter
        return MoviesViewController(refreshController: refreshController)
    }
}

final class MoviesPresenter {
    private let loaderView: MoviesLoaderView
    private let loader: MovieLoader
    
    init(loaderView: MoviesLoaderView, loader: MovieLoader) {
        self.loaderView = loaderView
        self.loader = loader
    }
    
    func load() {
        loaderView.display(LoadingViewModel(isLoading: true))
        loader.load { _ in
            self.loaderView.display(LoadingViewModel(isLoading: false))
        }
    }
}

struct LoadingViewModel {
    var isLoading: Bool
}

protocol MoviesLoaderView {
    func display(_ viewModel: LoadingViewModel)
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
    
    func display(_ viewModel: LoadingViewModel) {
        if viewModel.isLoading {
            view.beginRefreshing()
        } else {
            view.endRefreshing()
        }
    }
}

final class MoviesViewController: UITableViewController {
    private var refreshController: MoviesRefreshController?
    
    convenience init(refreshController: MoviesRefreshController) {
        self.init()
        self.refreshController = refreshController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl = refreshController?.view
        
        refreshController?.refresh()
    }
}

final class MoviesViewControllerTests: XCTestCase {
    
    func test_viewDidLoad_startsRefreshing() {
        let sut = makeSUT()
        
        XCTAssertTrue(sut.isLoading)
    }
    
    func test_userInitiatedRefresh_triggersMovieLoading() {
        let loader = LoaderSpy()
        let sut = makeSUT(with: loader)
        XCTAssertEqual(loader.receivedMessages.count, 1)
        
        sut.triggerUserInitiatedRefresh()
        XCTAssertEqual(loader.receivedMessages.count, 2)
        
        sut.triggerUserInitiatedRefresh()
        XCTAssertEqual(loader.receivedMessages.count, 3)
    }
    
    func test_viewDidLoad_loaderCompletionStopsRefreshing() {
        let loader = LoaderSpy()
        let sut = makeSUT(with: loader)
        
        loader.complete(with: anyNSError())
        
        XCTAssertFalse(sut.isLoading)
    }
    
    func test_viewDidLoad_rendersZeroMoviesFromReceivedEmptyList() {
        let loader = LoaderSpy()
        let sut = makeSUT(with: loader)
        
        loader.complete(with: [])
        
        XCTAssertEqual(sut.renderedMoviesCount, 0)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(with loader: MovieLoader = LoaderSpy(), file: StaticString = #file, line: UInt = #line) -> MoviesViewController {
        let sut = MoviesUIComposer.viewController(loader: loader)
        sut.loadViewIfNeeded()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    func anyNSError() -> Error {
        NSError(domain: "a domain", code: 0)
    }
    
    private class LoaderSpy: MovieLoader {
        typealias Message = (MovieLoader.Result) -> Void
        
        private(set) var receivedMessages = [Message]()
        
        func load(completion: @escaping Message) {
            receivedMessages.append(completion)
        }
        
        func complete(with movies: [Movie], at index: Int = 0) {
            receivedMessages[index](.success(movies))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            receivedMessages[index](.failure(error))
        }
    }
}

private extension MoviesViewController {
    var renderedMoviesCount: Int {
        let ds = tableView.dataSource!
        return ds.tableView(tableView, numberOfRowsInSection: 0)
    }
    
    var isLoading: Bool {
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
