//  Created by Marcell Magyar on 07.12.22.

import CinemaTime
import CinemaTimeiOS

public final class MoviesUIComposer {
    private init() {}
    
    public static func viewController(movieLoader: MovieLoader, imageLoader: MovieImageDataLoader) -> MoviesViewController {
        let refreshController = MoviesRefreshController()
        let viewController = MoviesViewController(refreshController: refreshController)
        viewController.title = MoviesPresenter.title
        refreshController.presenter = MoviesPresenter(
            moviesView: MoviesViewAdapter(
                controller: viewController,
                imageDataLoader: MainQueueDispatchDecorator(decoratee: imageLoader)),
            loadingView: WeakRefProxy(refreshController),
            loader: MainQueueDispatchDecorator(decoratee: movieLoader))
        return viewController
    }
}
