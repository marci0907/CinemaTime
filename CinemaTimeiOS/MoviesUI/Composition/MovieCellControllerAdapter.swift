//  Created by Marcell Magyar on 07.12.22.

final class MovieCellControllerAdapter: MoviesView {
    private weak var controller: MoviesViewController?
    
    init(controller: MoviesViewController) {
        self.controller = controller
    }
    
    func display(_ viewModel: MoviesViewModel) {
        controller?.cellControllers = viewModel.movies.map {
            let cellController = MovieCellController()
            cellController.presenter = MovieCellPresenter(
                movie: $0,
                movieCellView: cellController)
            return cellController
        }
    }
}
