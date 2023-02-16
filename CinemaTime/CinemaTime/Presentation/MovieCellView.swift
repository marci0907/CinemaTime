//  Created by Marcell Magyar on 07.12.22.

public protocol MovieCellView {
    associatedtype Image
    
    func display(_ viewModel: Image?)
}
