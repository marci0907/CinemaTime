//  Created by Marcell Magyar on 07.12.22.

import Foundation

struct MovieCellViewModel {
    let title: String
    let overview: String?
    let rating: String?
    let imageData: Data?
    let isLoading: Bool
    let shouldRetry: Bool
}

protocol MovieCellView {
    func display(_ viewModel: MovieCellViewModel)
}
