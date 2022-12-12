//  Created by Marcell Magyar on 07.12.22.

import CinemaTime

final class MoviesPresenter {
    private let moviesView: MoviesView
    private let loadingView: MoviesLoadingView
    private let loader: MovieLoader
    
    init(moviesView: MoviesView, loadingView: MoviesLoadingView, loader: MovieLoader) {
        self.moviesView = moviesView
        self.loadingView = loadingView
        self.loader = loader
    }
    
    func load() {
        loadingView.display(MoviesLoadingViewModel(isLoading: true))
        loader.load { [weak self] result in
            self?.loadingView.display(MoviesLoadingViewModel(isLoading: false))
            if let movies = try? result.get() {
                self?.moviesView.display(MoviesViewModel(movies: movies))
            }
        }
    }
}
