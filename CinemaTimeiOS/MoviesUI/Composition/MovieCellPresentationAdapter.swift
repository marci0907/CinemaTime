//  Created by Marcell Magyar on 08.12.22.

import CinemaTime

final class MovieCellPresentationAdapter<Image, View: MovieCellView>: MovieCellControllerDelegate where View.Image == Image {
    private let movie: Movie
    
    var presenter: MovieCellPresenter<Image, View>?
    
    init(movie: Movie) {
        self.movie = movie
    }
    
    func loadImageData() {
        presenter?.loadImageData(from: movie.imagePath)
    }
}
