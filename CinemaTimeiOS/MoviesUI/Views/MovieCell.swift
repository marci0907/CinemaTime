//  Created by Marcell Magyar on 07.12.22.

import UIKit

public final class MovieCell: UITableViewCell {
    public let imageContainer = UIView()
    public let posterView = UIImageView()
    public let titleLabel = UILabel()
    public let ratingLabel = UILabel()
    public let overviewLabel = UILabel()
    
    public lazy var retryButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(retry), for: .touchUpInside)
        return button
    }()
    
    var retryAction: (() -> Void)?
    
    @objc
    private func retry() {
        retryAction?()
    }
}
