//  Created by Marcell Magyar on 07.12.22.

import Foundation
import CinemaTime

final class MovieCellPresenter<Image, View: MovieCellView> where View.Image == Image {
    private let movie: Movie
    private let movieCellView: View
    private let imageDataLoader: MovieImageDataLoader
    private let imageMapper: (Data) -> Image?
    
    init(movie: Movie, movieCellView: View, imageDataLoader: MovieImageDataLoader, imageMapper: @escaping (Data) -> Image?) {
        self.movie = movie
        self.movieCellView = movieCellView
        self.imageDataLoader = imageDataLoader
        self.imageMapper = imageMapper
    }
    
    func loadImageData() {
        loadingStarted()
        
        let movie = self.movie
        _ = imageDataLoader.load(from: movie.imagePath) { [weak self] result in
            switch result {
            case let .success(data):
                self?.loadingFinished(with: data)
                
            default:
                self?.loadingFinishedWithError()
            }
        }
    }
    
    private func loadingStarted() {
        movieCellView.display(MovieCellViewModel<Image>(
            title: movie.title,
            overview: movie.overview,
            rating: presentableRating(for: movie.rating),
            image: nil,
            isLoading: true,
            shouldRetry: false
        ))
    }
    
    private func loadingFinished(with data: Data) {
        let image = imageMapper(data)
        movieCellView.display(MovieCellViewModel<Image>(
            title: movie.title,
            overview: movie.overview,
            rating: presentableRating(for: movie.rating),
            image: image,
            isLoading: false,
            shouldRetry: image == nil
        ))
    }
    
    private func loadingFinishedWithError() {
        movieCellView.display(MovieCellViewModel<Image>(
            title: movie.title,
            overview: movie.overview,
            rating: presentableRating(for: movie.rating),
            image: nil,
            isLoading: false,
            shouldRetry: true
        ))
    }
    
    private func presentableRating(for rating: Double?) -> String {
        "\(rating ?? 0.0)"
    }
}
