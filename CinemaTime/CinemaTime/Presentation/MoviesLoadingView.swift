//  Created by Marcell Magyar on 07.12.22.

public struct MoviesLoadingViewModel {
    public let isLoading: Bool
}

public protocol MoviesLoadingView {
    func display(_ viewModel: MoviesLoadingViewModel)
}
