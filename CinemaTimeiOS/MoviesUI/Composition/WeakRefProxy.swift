//  Created by Marcell Magyar on 07.12.22.

final class WeakRefProxy<T: AnyObject> {
    weak var object: T?
    
    init(_ object: T?) {
        self.object = object
    }
}

extension WeakRefProxy: MoviesLoadingView where T: MoviesLoadingView {
    func display(_ viewModel: MoviesLoadingViewModel) {
        object?.display(viewModel)
    }
}
