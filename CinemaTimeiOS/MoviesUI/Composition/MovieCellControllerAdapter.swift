//  Created by Marcell Magyar on 07.12.22.

import CinemaTime

final class MovieCellControllerAdapter: MoviesView {
    private weak var controller: MoviesViewController?
    private let imageDataLoader: MovieImageDataLoader
    
    init(controller: MoviesViewController, imageDataLoader: MovieImageDataLoader) {
        self.controller = controller
        self.imageDataLoader = imageDataLoader
    }
    
    func display(_ viewModel: MoviesViewModel) {
        controller?.cellControllers = viewModel.movies.map {
            let cellController = MovieCellController()
            cellController.presenter = MovieCellPresenter(
                movie: $0,
                movieCellView: WeakRefProxy(cellController),
                imageDataLoader: imageDataLoader)
            return cellController
        }
    }
}
