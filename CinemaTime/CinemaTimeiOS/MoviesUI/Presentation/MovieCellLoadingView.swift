//  Created by Marcell Magyar on 08.12.22.

struct MovieCellLoadingViewModel {
    let isLoading: Bool
}

protocol MovieCellLoadingView {
    func display(_ viewModel: MovieCellLoadingViewModel)
}
