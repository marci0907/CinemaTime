//  Created by Marcell Magyar on 07.12.22.

import CinemaTime

final class MovieCellPresenter {
    private let movie: Movie
    private let movieCellView: MovieCellView
    private let imageDataLoader: MovieImageDataLoader
    
    init(movie: Movie, movieCellView: MovieCellView, imageDataLoader: MovieImageDataLoader) {
        self.movie = movie
        self.movieCellView = movieCellView
        self.imageDataLoader = imageDataLoader
    }
    
    func loadImageData() {
        _ = imageDataLoader.load(from: movie.imagePath) { _ in }
        let ratingString = "\(movie.rating ?? 0.0)"
        movieCellView.display(MovieCellViewModel(title: movie.title, overview: movie.overview, rating: ratingString))
    }
}
