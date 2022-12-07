//  Created by Marcell Magyar on 07.12.22.

import Foundation
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
        loadingStarted()
        
        let movie = self.movie
        _ = imageDataLoader.load(from: movie.imagePath) { [weak self] result in
            switch result {
            case let .success(data):
                self?.loadingFinished(with: data)
                
            default:
                self?.loadingFinished(with: nil)   
            }
        }
    }
    
    private func loadingStarted() {
        movieCellView.display(MovieCellViewModel(
            title: movie.title,
            overview: movie.overview,
            rating: presentableRating(for: movie.rating),
            imageData: nil,
            isLoading: true,
            shouldRetry: false
        ))
    }
    
    private func loadingFinished(with data: Data?) {
        movieCellView.display(MovieCellViewModel(
            title: movie.title,
            overview: movie.overview,
            rating: presentableRating(for: movie.rating),
            imageData: data,
            isLoading: false,
            shouldRetry: data == nil
        ))
    }
    
    private func presentableRating(for rating: Double?) -> String {
        "\(rating ?? 0.0)"
    }
}
