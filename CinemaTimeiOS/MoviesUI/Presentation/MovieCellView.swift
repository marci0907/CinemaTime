//  Created by Marcell Magyar on 07.12.22.

protocol MovieCellView {
    associatedtype Image
    
    func display(_ viewModel: Image?)
}
