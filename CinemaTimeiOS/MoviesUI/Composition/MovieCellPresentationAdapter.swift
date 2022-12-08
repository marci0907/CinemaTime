//  Created by Marcell Magyar on 08.12.22.

final class MovieCellPresentationAdapter<Image, View: MovieCellView>: MovieCellControllerDelegate where View.Image == Image {
    var presenter: MovieCellPresenter<Image, View>?
    
    func loadImageData() {
        presenter?.loadImageData()
    }
}
