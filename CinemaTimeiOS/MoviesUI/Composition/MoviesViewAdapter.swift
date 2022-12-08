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
        controller?.cellControllers = viewModel.movies.map {
            let presentationAdapter = MovieCellPresentationAdapter<UIImage, WeakRefProxy<MovieCellController>>()
            let cellController = MovieCellController(
                viewModel: MovieCellPresenter<UIImage, MovieCellController>.map($0),
                delegate: presentationAdapter)
            presentationAdapter.presenter = MovieCellPresenter(
                movie: $0,
                view: WeakRefProxy(cellController),
                loadingView: WeakRefProxy(cellController),
                errorView: WeakRefProxy(cellController),
                imageDataLoader: imageDataLoader,
                imageMapper: UIImage.init)
            return cellController
        }
    }
}
