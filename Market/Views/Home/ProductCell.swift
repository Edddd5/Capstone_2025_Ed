//
//  ProductCell.swift
//  Market
//
//  Created by 장동혁 on 4/10/25.
//

import UIKit

class ProductCell: UITableViewCell {
    // MARK: - UI Components
    let productImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .lightGray
        imageView.layer.cornerRadius = 8
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let priceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let placeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .gray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let statusView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGreen
        view.layer.cornerRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // 위시리스트 버튼
    let wishlistButton: UIButton = {
        let button = UIButton(type: .system)
        let heartImage = UIImage(systemName: "heart")
        button.setImage(heartImage, for: .normal)
        button.tintColor = .gray
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Properties
    var postId: Int = 0
    var isInWishlist: Bool = false
    var toggleWishlistAction: ((Int, Bool) -> Void)?
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    private func setupViews() {
        contentView.addSubview(productImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(priceLabel)
        contentView.addSubview(placeLabel)
        contentView.addSubview(statusView)
        contentView.addSubview(wishlistButton)
        statusView.addSubview(statusLabel)
        
        NSLayoutConstraint.activate([
            productImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            productImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            productImageView.widthAnchor.constraint(equalToConstant: 80),
            productImageView.heightAnchor.constraint(equalToConstant: 80),
            
            titleLabel.leadingAnchor.constraint(equalTo: productImageView.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: wishlistButton.leadingAnchor, constant: -8),
            
            priceLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            priceLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            priceLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            
            placeLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            placeLabel.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 4),
            placeLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            
            statusView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            statusView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            statusView.widthAnchor.constraint(equalToConstant: 60),
            statusView.heightAnchor.constraint(equalToConstant: 24),
            
            statusLabel.leadingAnchor.constraint(equalTo: statusView.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: statusView.trailingAnchor),
            statusLabel.topAnchor.constraint(equalTo: statusView.topAnchor),
            statusLabel.bottomAnchor.constraint(equalTo: statusView.bottomAnchor),
            
            // 위시리스트 버튼 제약 조건
            wishlistButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            wishlistButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            wishlistButton.widthAnchor.constraint(equalToConstant: 32),
            wishlistButton.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
    
    private func setupActions() {
        wishlistButton.addTarget(self, action: #selector(wishlistButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func wishlistButtonTapped() {
        // 버튼 비활성화로 중복 클릭 방지
        wishlistButton.isEnabled = false
        
        // 위시리스트 상태 반전 (추가 또는 제거)
        let shouldAdd = !isInWishlist
        
        // 뷰 컨트롤러의 액션 호출
        toggleWishlistAction?(postId, shouldAdd)
    }
    
    // MARK: - Configuration Methods
    func configure(with post: Post, isInWishlist: Bool) {
        self.postId = post.id
        self.isInWishlist = isInWishlist
        
        titleLabel.text = post.title
        priceLabel.text = formatPrice(post.price)
        placeLabel.text = post.place ?? "위치 정보 없음"
        
        // 상태 설정
        configureStatus(post.status)
        
        // 위시리스트 버튼 업데이트
        updateWishlistButtonAppearance()
        
        // 첫 번째 이미지 로드
        if let imageUrls = post.imageUrls, !imageUrls.isEmpty {
            // 서버 URL과 이미지 경로 조합
            let baseURL = "https://hanlumi.co.kr/images/"
            let imageURLString = baseURL + imageUrls[0]
            
            if let imageUrl = URL(string: imageURLString) {
                loadImage(from: imageUrl)
            }
        } else {
            productImageView.image = nil
        }
    }
    
    // 위시리스트 상태 업데이트 메서드
    func updateWishlistState(isInWishlist: Bool) {
        self.isInWishlist = isInWishlist
        updateWishlistButtonAppearance()
        wishlistButton.isEnabled = true
    }
    
    // 위시리스트 버튼 외관 업데이트
    func updateWishlistButtonAppearance() {
        if isInWishlist {
            // 위시리스트에 있는 경우 - 채워진 하트
            let heartImage = UIImage(systemName: "heart.fill")
            wishlistButton.setImage(heartImage, for: .normal)
            wishlistButton.tintColor = .systemRed
        } else {
            // 위시리스트에 없는 경우 - 빈 하트
            let heartImage = UIImage(systemName: "heart")
            wishlistButton.setImage(heartImage, for: .normal)
            wishlistButton.tintColor = .gray
        }
    }
    
    // 가격 포맷 메서드
    private func formatPrice(_ price: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: price)).map { "\($0)원" } ?? "\(price)원"
    }
    
    // 상태에 따른 UI 설정
    private func configureStatus(_ status: Int) {
        switch status {
        case 0:
            statusView.backgroundColor = .systemGreen
            statusLabel.text = "판매중"
        case 1:
            statusView.backgroundColor = .systemOrange
            statusLabel.text = "예약중"
        case 2:
            statusView.backgroundColor = .systemGray
            statusLabel.text = "판매완료"
        default:
            statusView.isHidden = true
        }
    }
    
    // 이미지 로드 메서드
    private func loadImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  error == nil,
                  let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    self?.productImageView.image = UIImage(named: "placeholder")
                }
                return
            }
            
            DispatchQueue.main.async {
                self.productImageView.image = image
            }
        }.resume()
    }
    
    // 셀 재사용 준비
    override func prepareForReuse() {
        super.prepareForReuse()
        productImageView.image = nil
        titleLabel.text = nil
        priceLabel.text = nil
        placeLabel.text = nil
        statusView.isHidden = false
        wishlistButton.isEnabled = true
    }
    
    // 정보를 가져오지 못했을 때 폴백 UI 설정
    func configureFallback(postId: Int) {
        self.postId = postId
        
        titleLabel.text = "상품 정보를 불러오는 중..."
        priceLabel.text = "가격 정보 없음"
        placeLabel.text = "위치 정보 없음"
        productImageView.image = UIImage(systemName: "photo")
        productImageView.tintColor = .systemGray3
        
        statusView.isHidden = true
        
        // 위시리스트 상태는 기본적으로 true (위시리스트 화면이므로)
        isInWishlist = true
        updateWishlistButtonAppearance()
    }
}

// UIButton Extension for centering image and Title
extension UIButton {
    func centerImageAndButton(spacing: CGFloat = 6.0) {
        self.contentHorizontalAlignment = .center
        self.contentVerticalAlignment = .center
        
        let imageWidth = self.imageView?.image?.size.width ?? 0
        let imageHeight = self.imageView?.image?.size.height ?? 0
        
        let labelWidth = self.titleLabel?.intrinsicContentSize.width ?? 0
        let labelHeight = self.titleLabel?.intrinsicContentSize.height ?? 0
        
        self.imageEdgeInsets = UIEdgeInsets(
            top: -labelHeight - spacing/2,
            left: 0,
            bottom: 0,
            right: -labelWidth
        )
        
        self.titleEdgeInsets = UIEdgeInsets(
            top: 0,
            left: -imageWidth,
            bottom: -imageHeight - spacing/2,
            right: 0
        )
    }
}
