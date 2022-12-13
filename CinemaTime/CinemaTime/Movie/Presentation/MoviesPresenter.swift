//  Created by Marcell Magyar on 07.12.22.

public final class MoviesPresenter {
    private let moviesView: MoviesView
    private let loadingView: MoviesLoadingView
    private let loader: MovieLoader
    
    public init(moviesView: MoviesView, loadingView: MoviesLoadingView, loader: MovieLoader) {
        self.moviesView = moviesView
        self.loadingView = loadingView
        self.loader = loader
    }
    
    public func load() {
        loadingView.display(MoviesLoadingViewModel(isLoading: true))
        loader.load { [weak self] result in
            self?.loadingView.display(MoviesLoadingViewModel(isLoading: false))
            if let movies = try? result.get() {
                self?.moviesView.display(MoviesViewModel(movies: movies))
            }
        }
    }
}
