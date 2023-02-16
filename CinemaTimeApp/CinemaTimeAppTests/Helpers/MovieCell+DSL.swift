//  Created by Marcell Magyar on 13.12.22.

import UIKit
import CinemaTimeiOS

extension MovieCell {
    var isRetryButtonVisible: Bool {
        !retryButton.isHidden
    }
    
    var renderedImage: UIImage? {
        posterView.image
    }
    
    var renderedImageData: Data? {
        posterView.image?.pngData()
    }
    
    var isShowingImageLoader: Bool {
        imageLoadingIndicator.isAnimating
    }
    
    func triggerRetryAction() {
        retryButton.triggerAction()
    }
}
