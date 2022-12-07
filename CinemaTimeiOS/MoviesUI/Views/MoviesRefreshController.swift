//  Created by Marcell Magyar on 07.12.22.

import UIKit

final class MoviesRefreshController: NSObject, MoviesLoadingView {
    var presenter: MoviesPresenter?
    
    lazy var view: UIRefreshControl = {
        let view = UIRefreshControl()
        view.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return view
    }()
    
    @objc
    func refresh() {
        presenter?.load()
    }
    
    func display(_ viewModel: MoviesLoadingViewModel) {
        if viewModel.isLoading {
            view.beginRefreshing()
        } else {
            view.endRefreshing()
        }
    }
}
