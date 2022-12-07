//  Created by Marcell Magyar on 07.12.22.

struct MovieCellViewModel {
    let title: String
    let overview: String?
    let rating: String?
}

protocol MovieCellView {
    func display(_ viewModel: MovieCellViewModel)
}
