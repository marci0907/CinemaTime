//  Created by Marcell Magyar on 07.12.22.

import UIKit
import CinemaTime

public final class MoviesRefreshController: NSObject, MoviesLoadingView {
    public var presenter: MoviesPresenter?
    
    lazy var view: UIRefreshControl = {
        let view = UIRefreshControl()
        view.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return view
    }()
    
    @objc
    func refresh() {
        presenter?.load()
    }
    
    public func display(_ viewModel: MoviesLoadingViewModel) {
        if viewModel.isLoading {
            view.beginRefreshing()
        } else {
            view.endRefreshing()
        }
    }
}
