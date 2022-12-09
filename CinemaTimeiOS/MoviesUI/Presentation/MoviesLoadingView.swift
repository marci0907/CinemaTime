//  Created by Marcell Magyar on 07.12.22.

struct MoviesLoadingViewModel {
    let isLoading: Bool
}

protocol MoviesLoadingView {
    func display(_ viewModel: MoviesLoadingViewModel)
}
