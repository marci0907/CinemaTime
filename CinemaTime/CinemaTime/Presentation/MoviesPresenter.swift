//  Created by Marcell Magyar on 07.12.22.

import Foundation

public final class MoviesPresenter {
    private let moviesView: MoviesView
    private let loadingView: MoviesLoadingView
    private let loader: MovieLoader
    
    public static var title: String {
        NSLocalizedString(
            "NOW_PLAYING_MOVIES_TITLE",
            tableName: "Movies",
            bundle: Bundle(for: MoviesPresenter.self),
            comment: "Title for movies view")
    }
    
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
