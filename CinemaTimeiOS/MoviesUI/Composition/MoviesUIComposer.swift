//  Created by Marcell Magyar on 07.12.22.

import CinemaTime

public final class MoviesUIComposer {
    private init() {}
    
    public static func viewController(loader: MovieLoader) -> MoviesViewController {
        let refreshController = MoviesRefreshController()
        let viewController = MoviesViewController(refreshController: refreshController)
        refreshController.presenter = MoviesPresenter(
            moviesView: MovieCellControllerAdapter(controller: viewController),
            loadingView: WeakRefProxy(refreshController),
            loader: loader)
        return viewController
    }
}
