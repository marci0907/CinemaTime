//  Created by Marcell Magyar on 07.12.22.

import UIKit

struct MovieCellViewModel {
    let title: String
    let overview: String?
    let rating: String?
}

protocol MovieCellControllerDelegate {
    func loadImageData()
    func cancelImageDataLoading()
}

final class MovieCellController {
    private let viewModel: MovieCellViewModel
    private let delegate: MovieCellControllerDelegate
    
    private var view: MovieCell?
    
    init(viewModel: MovieCellViewModel, delegate: MovieCellControllerDelegate) {
        self.delegate = delegate
        self.viewModel = viewModel
    }
    
    func view(in tableView: UITableView) -> UITableViewCell {
        view = tableView.dequeueReusableCell()
        configureView()
        
        delegate.loadImageData()
        
        return view!
    }
    
    func preloadImageData(for cell: UITableViewCell) {
        self.view = cell as? MovieCell
        delegate.loadImageData()
    }
    
    func cancelImageLoading() {
        delegate.cancelImageDataLoading()
        releaseCellForReuse()
    }
    
    private func configureView() {
        view?.posterView.setImageAnimated(nil)
        view?.titleLabel.text = viewModel.title
        view?.overviewLabel.text = viewModel.overview
        view?.ratingLabel.text = viewModel.rating
        view?.retryAction = delegate.loadImageData
    }
    
    private func releaseCellForReuse() {
        view = nil
    }
}

extension MovieCellController: MovieCellView {
    func display(_ viewModel: UIImage?) {
        view?.posterView.setImageAnimated(viewModel)
    }
}

extension MovieCellController: MovieCellLoadingView {
    func display(_ viewModel: MovieCellLoadingViewModel) {
        if viewModel.isLoading {
            view?.imageLoadingIndicator.startAnimating()
        } else {
            view?.imageLoadingIndicator.stopAnimating()
        }
    }
}

extension MovieCellController: MovieCellErrorView {
    func display(_ viewModel: MovieCellErrorViewModel) {
        view?.imageContainer.isHidden = viewModel.shouldRetry
        view?.retryButton.isHidden = !viewModel.shouldRetry
    }
}
