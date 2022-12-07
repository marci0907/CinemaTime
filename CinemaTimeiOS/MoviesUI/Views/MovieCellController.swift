//  Created by Marcell Magyar on 07.12.22.

import UIKit

final class MovieCellController: MovieCellView {
    var presenter: MovieCellPresenter?
    
    private var view: MovieCell?
    
    func view(in tableView: UITableView) -> UITableViewCell {
        view = tableView.dequeueReusableCell()
        presenter?.loadImageData()
        return view!
    }
    
    func display(_ viewModel: MovieCellViewModel) {
        view?.titleLabel.text = viewModel.title
        view?.overviewLabel.text = viewModel.overview
        view?.ratingLabel.text = viewModel.rating
    }
}
