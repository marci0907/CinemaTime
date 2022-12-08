//  Created by Marcell Magyar on 07.12.22.

import Foundation
import CinemaTime

final class MovieCellPresenter<Image, View: MovieCellView> where View.Image == Image {
    private let view: View
    private let loadingView: MovieCellLoadingView
    private let errorView: MovieCellErrorView
    private let imageDataLoader: MovieImageDataLoader
    private let imageMapper: (Data) -> Image?
    
    init(
        view: View,
        loadingView: MovieCellLoadingView,
        errorView: MovieCellErrorView,
        imageDataLoader: MovieImageDataLoader,
        imageMapper: @escaping (Data) -> Image?
    ) {
        self.view = view
        self.loadingView = loadingView
        self.errorView = errorView
        self.imageDataLoader = imageDataLoader
        self.imageMapper = imageMapper
    }
    
    func loadImageData(from imagePath: String?) {
        loadingStarted()
        
        _ = imageDataLoader.load(from: imagePath) { [weak self] result in
            switch result {
            case let .success(data):
                self?.loadingFinished(with: data)
                
            default:
                self?.loadingFinishedWithError()
            }
        }
    }
    
    static func map(_ movie: Movie) -> MovieCellViewModel {
        MovieCellViewModel(
            title: movie.title,
            overview: movie.overview,
            rating: presentableRating(for: movie.rating)
        )
    }
    
    private func loadingStarted() {
        loadingView.display(MovieCellLoadingViewModel(isLoading: true))
        errorView.display(MovieCellErrorViewModel(shouldRetry: false))
    }
    
    private func loadingFinished(with data: Data) {
        let image = imageMapper(data)
        
        view.display(image)
        loadingView.display(MovieCellLoadingViewModel(isLoading: false))
        errorView.display(MovieCellErrorViewModel(shouldRetry: image == nil))
    }
    
    private func loadingFinishedWithError() {
        loadingView.display(MovieCellLoadingViewModel(isLoading: false))
        errorView.display(MovieCellErrorViewModel(shouldRetry: true))
    }
    
    private static func presentableRating(for rating: Double?) -> String {
        "\(rating ?? 0.0)"
    }
}
