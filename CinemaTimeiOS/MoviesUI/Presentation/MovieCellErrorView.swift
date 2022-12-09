//  Created by Marcell Magyar on 08.12.22.

struct MovieCellErrorViewModel {
    let shouldRetry: Bool
}

protocol MovieCellErrorView {
    func display(_ viewModel: MovieCellErrorViewModel)
}
