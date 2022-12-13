//  Created by Marcell Magyar on 08.12.22.

public struct MovieCellLoadingViewModel {
    let isLoading: Bool
}

public protocol MovieCellLoadingView {
    func display(_ viewModel: MovieCellLoadingViewModel)
}
