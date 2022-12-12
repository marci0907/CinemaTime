//  Created by Marcell Magyar on 07.12.22.

import UIKit
import CinemaTime

final class MoviesViewAdapter: MoviesView {
    private weak var controller: MoviesViewController?
    private let imageDataLoader: MovieImageDataLoader
    
    init(controller: MoviesViewController, imageDataLoader: MovieImageDataLoader) {
        self.controller = controller
        self.imageDataLoader = imageDataLoader
    }
    
    func display(_ viewModel: MoviesViewModel) {
        controller?.cellControllers = viewModel.movies
            .sorted(by: { $0.releaseDate ?? Date() > $1.releaseDate ?? Date() })
            .map {
                let presentationAdapter = MovieCellPresentationAdapter<UIImage, WeakRefProxy<MovieCellController>>(movie: $0)
                let cellController = MovieCellController(
                    viewModel: MovieCellPresenter<UIImage, MovieCellController>.map($0),
                    delegate: presentationAdapter)
                presentationAdapter.presenter = MovieCellPresenter(
                    view: WeakRefProxy(cellController),
                    loadingView: WeakRefProxy(cellController),
                    errorView: WeakRefProxy(cellController),
                    imageDataLoader: imageDataLoader,
                    imageMapper: UIImage.init)
                return cellController
            }
    }
}
