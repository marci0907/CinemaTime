//  Created by Marcell Magyar on 07.12.22.

import CinemaTime

final class MoviesPresenter {
    private let moviesView: MoviesView
    private let loaderView: MoviesLoadingView
    private let loader: MovieLoader
    
    init(moviesView: MoviesView, loadingView: MoviesLoadingView, loader: MovieLoader) {
        self.moviesView = moviesView
        self.loaderView = loadingView
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
