//  Created by Marcell Magyar on 07.12.22.

import UIKit

protocol MovieCellControllerDelegate {
    func loadImageData()
}

final class MovieCellController: MovieCellView {
    let delegate: MovieCellControllerDelegate
    
    private var view: MovieCell?
    
    init(delegate: MovieCellControllerDelegate) {
        self.delegate = delegate
    }
    
    func view(in tableView: UITableView) -> UITableViewCell {
        view = tableView.dequeueReusableCell()
        delegate.loadImageData()
        return view!
    }
    
    func display(_ viewModel: MovieCellViewModel<UIImage>) {
        view?.posterView.image = viewModel.image
        view?.titleLabel.text = viewModel.title
        view?.overviewLabel.text = viewModel.overview
        view?.ratingLabel.text = viewModel.rating
        view?.retryButton.isHidden = !viewModel.shouldRetry
    }
}
