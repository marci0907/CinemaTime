//  Created by Marcell Magyar on 07.12.22.

import CinemaTime

struct MoviesViewModel {
    let movies: [Movie]
}

protocol MoviesView {
    func display(_ viewModel: MoviesViewModel)
}
