//  Created by Marcell Magyar on 07.12.22.

public struct MoviesViewModel {
    public let movies: [Movie]
}

public protocol MoviesView {
    func display(_ viewModel: MoviesViewModel)
}
