//  Created by Marcell Magyar on 07.12.22.

import CinemaTime

final class MovieCellPresenter {
    private let movieCellView: MovieCellView
    private let movie: Movie
    
    init(movie: Movie, movieCellView: MovieCellView) {
        self.movie = movie
        self.movieCellView = movieCellView
    }
    
    func loadImageData() {
        let ratingString = "\(movie.rating ?? 0.0)"
        movieCellView.display(MovieCellViewModel(title: movie.title, overview: movie.overview, rating: ratingString))
    }
}
