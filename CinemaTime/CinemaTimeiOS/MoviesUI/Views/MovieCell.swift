//  Created by Marcell Magyar on 07.12.22.

import UIKit

public final class MovieCell: UITableViewCell {
    private let contentStackView = UIStackView()
    private let imageContentView = UIView()
    public let imageContainer = UIView()
    public let imageLoadingIndicator = UIActivityIndicatorView(style: .large)
    public let posterView = UIImageView()
    public let titleLabel = UILabel()
    private let ratingView = UIStackView()
    public let ratingLabel = UILabel()
    public let overviewLabel = UILabel()
    
    public lazy var retryButton: UIButton = {
        let button = UIButton()
        button.setTitle("Retry", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(retry), for: .touchUpInside)
        return button
    }()
    
    var retryAction: (() -> Void)?
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    @objc
    private func retry() {
        retryAction?()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

private extension MovieCell {
    func setupUI() {
        contentView.addSubview(contentStackView)
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        
        contentStackView.axis = .vertical
        contentStackView.spacing = 10
        
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            contentStackView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
            contentStackView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20)
        ])
        
        setupImageContentView()
        setupTitle()
    }
    
    func setupImageContentView() {
        contentStackView.addArrangedSubview(imageContentView)
        
        setupImageContainer()
        setupRetryButton()
    }
    
    func setupImageContainer() {
        imageContentView.addSubview(imageContainer)
        imageContainer.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageContainer.topAnchor.constraint(equalTo: imageContentView.topAnchor),
            imageContainer.bottomAnchor.constraint(equalTo: imageContentView.bottomAnchor),
            imageContainer.leftAnchor.constraint(equalTo: imageContentView.leftAnchor),
            imageContainer.rightAnchor.constraint(equalTo: imageContentView.rightAnchor)
        ])
        
        imageContainer.addSubview(posterView)
        posterView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            posterView.topAnchor.constraint(equalTo: imageContainer.topAnchor),
            posterView.bottomAnchor.constraint(equalTo: imageContainer.bottomAnchor),
            posterView.leftAnchor.constraint(equalTo: imageContainer.leftAnchor),
            posterView.rightAnchor.constraint(equalTo: imageContainer.rightAnchor)
        ])
        
        imageContainer.insertSubview(imageLoadingIndicator, aboveSubview: posterView)
        imageLoadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageLoadingIndicator.centerXAnchor.constraint(equalTo: imageContainer.centerXAnchor),
            imageLoadingIndicator.centerYAnchor.constraint(equalTo: imageContainer.centerYAnchor)
        ])
        
        setupRatingView()
    }
    
    func setupRatingView() {
        imageContainer.addSubview(ratingView)
        ratingView.translatesAutoresizingMaskIntoConstraints = false
        
        ratingView.axis = .horizontal
        ratingView.spacing = 5
        
        NSLayoutConstraint.activate([
            ratingView.bottomAnchor.constraint(equalTo: imageContainer.bottomAnchor, constant: -15),
            ratingView.rightAnchor.constraint(equalTo: imageContainer.rightAnchor, constant: -15)
        ])
        
        ratingView.addArrangedSubview(ratingLabel)
        
        ratingLabel.textColor = .yellow
        
        let starView = UIImageView()
        ratingView.addArrangedSubview(starView)
        
        starView.image = UIImage(systemName: "star.fill")
        starView.tintColor = .yellow
    }
    
    func setupRetryButton() {
        imageContentView.addSubview(retryButton)
        retryButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            retryButton.topAnchor.constraint(equalTo: imageContentView.topAnchor),
            retryButton.bottomAnchor.constraint(equalTo: imageContentView.bottomAnchor),
            retryButton.leftAnchor.constraint(equalTo: imageContentView.leftAnchor),
            retryButton.rightAnchor.constraint(equalTo: imageContentView.rightAnchor)
        ])
    }
    
    func setupTitle() {
        contentStackView.addArrangedSubview(titleLabel)
        
        titleLabel.font = .systemFont(ofSize: 20)
        titleLabel.numberOfLines = 0
    }
}
