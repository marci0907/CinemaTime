//  Created by Marcell Magyar on 08.12.22.

public struct MovieCellErrorViewModel {
    let shouldRetry: Bool
}

public protocol MovieCellErrorView {
    func display(_ viewModel: MovieCellErrorViewModel)
}
