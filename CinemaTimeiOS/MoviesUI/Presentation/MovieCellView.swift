//  Created by Marcell Magyar on 07.12.22.

import Foundation

struct MovieCellViewModel<Image> {
    let title: String
    let overview: String?
    let rating: String?
    let image: Image?
    let isLoading: Bool
    let shouldRetry: Bool
}

protocol MovieCellView {
    associatedtype Image
    
    func display(_ viewModel: MovieCellViewModel<Image>)
}
