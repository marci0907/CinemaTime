//  Created by Marcell Magyar on 07.12.22.

import CinemaTime

public final class MoviesUIComposer {
    private init() {}
    
    public static func viewController(movieLoader: MovieLoader, imageLoader: MovieImageDataLoader) -> MoviesViewController {
        let refreshController = MoviesRefreshController()
        let viewController = MoviesViewController(refreshController: refreshController)
        refreshController.presenter = MoviesPresenter(
            moviesView: MoviesViewAdapter(
                controller: viewController,
                imageDataLoader: MainQueueDispatchDecorator(decoratee: imageLoader)),
            loadingView: WeakRefProxy(refreshController),
            loader: movieLoader)
        return viewController
    }
}
