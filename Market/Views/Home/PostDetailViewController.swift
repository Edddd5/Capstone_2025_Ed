//
//  PostDetailViewController.swift
//  Market
//
//  Created by 장동혁 on 3/28/25.
//

import UIKit

class PostDetailViewController: UIViewController {
    
    // MARK: - Properties
    private var post: Post
    private var isInWishlist: Bool = false
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // MARK: - UI Components
    private let imageCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .white
        collectionView.register(PostImageCell.self, forCellWithReuseIdentifier: "PostImageCell")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    private let pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.currentPageIndicatorTintColor = .systemBlue
        pageControl.pageIndicatorTintColor = .lightGray
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        return pageControl
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let placeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .gray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let contentLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let statusView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGreen
        view.layer.cornerRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .darkGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let sellerInfoView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let sellerProfileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 20
        imageView.backgroundColor = .lightGray
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let sellerNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let wishlistButton: UIButton = {
        let button = UIButton(type: .system)
        let heartImage = UIImage(systemName: "heart")
        button.setImage(heartImage, for: .normal)
        button.tintColor = .gray
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let chatButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("채팅하기", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Initializer
    init(post: Post) {
        self.post = post
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupNavigationBar()
        setupScrollView()
        setupViews()
        configureWithPost()
        setupActions()
        
        // 위시리스트 상태 확인
        checkWishlistStatus()
        
        // 조회수 증가 API 호출
        loadPostDetail()
    }
    
    // MARK: - Setup Methods
    private func setupNavigationBar() {
        title = "상품 상세"
        
        // 뒤로가기 버튼 커스텀
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        backButton.tintColor = .black
        navigationItem.leftBarButtonItem = backButton
        
        // 공유 버튼 추가
        let shareButton = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up"),
            style: .plain,
            target: self,
            action: #selector(shareButtonTapped)
        )
        shareButton.tintColor = .black
        
        // 더보기 버튼 추가
        let moreButton = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis"),
            style: .plain,
            target: self,
            action: #selector(moreButtonTapped)
        )
        moreButton.tintColor = .black
        
        navigationItem.rightBarButtonItems = [moreButton, shareButton]
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func setupViews() {
        // 이미지 컬렉션 뷰 설정
        imageCollectionView.delegate = self
        imageCollectionView.dataSource = self
        
        // 컴포넌트 추가
        contentView.addSubview(imageCollectionView)
        contentView.addSubview(pageControl)
        contentView.addSubview(titleLabel)
        contentView.addSubview(statusView)
        statusView.addSubview(statusLabel)
        contentView.addSubview(priceLabel)
        contentView.addSubview(placeLabel)
        contentView.addSubview(dateLabel)
        contentView.addSubview(sellerInfoView)
        sellerInfoView.addSubview(sellerProfileImageView)
        sellerInfoView.addSubview(sellerNameLabel)
        contentView.addSubview(contentLabel)
        
        // 하단 버튼 뷰 추가
        view.addSubview(wishlistButton)
        view.addSubview(chatButton)
        
        // 레이아웃 설정
        NSLayoutConstraint.activate([
            // 이미지 컬렉션 뷰
            imageCollectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageCollectionView.heightAnchor.constraint(equalTo: view.widthAnchor), // 정사각형
            
            // 페이지 컨트롤
            pageControl.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: imageCollectionView.bottomAnchor, constant: -8),
            
            // 상태 표시
            statusView.topAnchor.constraint(equalTo: imageCollectionView.bottomAnchor, constant: 16),
            statusView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            statusView.widthAnchor.constraint(equalToConstant: 60),
            statusView.heightAnchor.constraint(equalToConstant: 24),
            
            statusLabel.leadingAnchor.constraint(equalTo: statusView.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: statusView.trailingAnchor),
            statusLabel.topAnchor.constraint(equalTo: statusView.topAnchor),
            statusLabel.bottomAnchor.constraint(equalTo: statusView.bottomAnchor),
            
            // 날짜 레이블
            dateLabel.centerYAnchor.constraint(equalTo: statusView.centerYAnchor),
            dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // 제목
            titleLabel.topAnchor.constraint(equalTo: statusView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // 가격
            priceLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            priceLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            priceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // 위치
            placeLabel.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 8),
            placeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            placeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // 판매자 정보
            sellerInfoView.topAnchor.constraint(equalTo: placeLabel.bottomAnchor, constant: 24),
            sellerInfoView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            sellerInfoView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            sellerInfoView.heightAnchor.constraint(equalToConstant: 80),
            
            sellerProfileImageView.leadingAnchor.constraint(equalTo: sellerInfoView.leadingAnchor, constant: 16),
            sellerProfileImageView.centerYAnchor.constraint(equalTo: sellerInfoView.centerYAnchor),
            sellerProfileImageView.widthAnchor.constraint(equalToConstant: 40),
            sellerProfileImageView.heightAnchor.constraint(equalToConstant: 40),
            
            sellerNameLabel.leadingAnchor.constraint(equalTo: sellerProfileImageView.trailingAnchor, constant: 12),
            sellerNameLabel.centerYAnchor.constraint(equalTo: sellerInfoView.centerYAnchor),
            
            // 내용
            contentLabel.topAnchor.constraint(equalTo: sellerInfoView.bottomAnchor, constant: 24),
            contentLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contentLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            contentLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
            
            // 하단 버튼
            wishlistButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            wishlistButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            wishlistButton.widthAnchor.constraint(equalToConstant: 50),
            wishlistButton.heightAnchor.constraint(equalToConstant: 50),
            
            chatButton.leadingAnchor.constraint(equalTo: wishlistButton.trailingAnchor, constant: 16),
            chatButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            chatButton.centerYAnchor.constraint(equalTo: wishlistButton.centerYAnchor),
            chatButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupActions() {
        wishlistButton.addTarget(self, action: #selector(wishlistButtonTapped), for: .touchUpInside)
        chatButton.addTarget(self, action: #selector(chatButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Configuration
    private func configureWithPost() {
        // 기본 정보 설정
        titleLabel.text = post.title
        priceLabel.text = formatPrice(post.price)
        placeLabel.text = post.place ?? "위치 정보 없음"
        contentLabel.text = post.content
        
        // 날짜 포맷팅
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = dateFormatter.date(from: post.createdAt) {
            dateFormatter.dateFormat = "yyyy.MM.dd"
            dateLabel.text = dateFormatter.string(from: date)
        }
        
        // 이미지 설정
        if let imageUrls = post.imageUrls, !imageUrls.isEmpty {
            pageControl.numberOfPages = imageUrls.count
            pageControl.isHidden = imageUrls.count <= 1
            imageCollectionView.reloadData()
        } else {
            pageControl.isHidden = true
        }
        
        // 판매자 정보 설정
        if let user = post.user {
            sellerNameLabel.text = user.nickname
            
            // 프로필 이미지 설정 (있을 경우)
            if let profileImageUrl = user.profileImageUrl,
               let url = URL(string: "http://localhost:8080/images/\(profileImageUrl)") {
                loadImage(from: url, to: sellerProfileImageView)
            }
        }
        
        // 상태 설정
        configureStatus(post.status)
    }
    
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
    
    private func checkWishlistStatus() {
        // 로그인 상태 확인
        guard isLoggedIn() else { return }
        
        // 위시리스트 목록 가져오기
        NetworkManager.shared.getMyWishList { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let wishlist):
                // 현재 상품이 위시리스트에 있는지 확인
                let isInWishlist = wishlist.contains { $0.postId == self.post.id }
                
                DispatchQueue.main.async {
                    self.isInWishlist = isInWishlist
                    self.updateWishlistButtonAppearance()
                }
                
            case .failure(let error):
                print("Failed to load wishlist: \(error.localizedDescription)")
            }
        }
    }
    
    private func updateWishlistButtonAppearance() {
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
    
    // MARK: - Actions
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func shareButtonTapped() {
        let text = "\(post.title)\n가격: \(formatPrice(post.price))\n\n앱에서 더 많은 상품을 확인하세요!"
        let activityViewController = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        present(activityViewController, animated: true)
    }
    
    @objc private func moreButtonTapped() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        // 내 게시물인 경우
        if isMyPost() {
            alertController.addAction(UIAlertAction(title: "수정하기", style: .default) { [weak self] _ in
                self?.editPost()
            })
            
            alertController.addAction(UIAlertAction(title: "삭제하기", style: .destructive) { [weak self] _ in
                self?.deletePost()
            })
        } else {
            // 다른 사람의 게시물인 경우
            alertController.addAction(UIAlertAction(title: "신고하기", style: .destructive) { [weak self] _ in
                self?.reportPost()
            })
        }
        
        alertController.addAction(UIAlertAction(title: "취소", style: .cancel))
        
        present(alertController, animated: true)
    }
    
    @objc private func wishlistButtonTapped() {
        // 로그인 상태 확인
        guard isLoggedIn() else {
            showLoginRequiredAlert()
            return
        }
        
        if isInWishlist {
            // 위시리스트에서 제거
            NetworkManager.shared.removeFromWishlist(postId: post.id) { [weak self] result in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self.isInWishlist = false
                        self.updateWishlistButtonAppearance()
                    case .failure(let error):
                        self.showAlert(title: "오류", message: error.localizedDescription)
                    }
                }
            }
        } else {
            // 위시리스트에 추가
            NetworkManager.shared.addToWishlist(postId: post.id) { [weak self] result in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self.isInWishlist = true
                        self.updateWishlistButtonAppearance()
                    case .failure(let error):
                        self.showAlert(title: "오류", message: error.localizedDescription)
                    }
                }
            }
        }
    }
    
    @objc private func chatButtonTapped() {
        // 로그인 상태 확인
        guard isLoggedIn() else {
            showLoginRequiredAlert()
            return
        }
        
        // 내 게시물인지 확인
        if isMyPost() {
            showAlert(title: "알림", message: "본인의 게시물과는 채팅할 수 없습니다.")
            return
        }
        
        // 채팅 화면으로 이동 (구현 예정)
        showAlert(title: "알림", message: "채팅 기능은 준비 중입니다.")
    }
    
    // MARK: - API Calls
    private func loadPostDetail() {
        NetworkManager.shared.fetchPost(id: post.id) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let post):
                    // 새로운 데이터로 UI 업데이트
                    self.post = post
                    self.configureWithPost()
                case .failure(let error):
                    print("Failed to load post detail: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func editPost() {
        // 수정 화면으로 이동 (구현 예정)
        showAlert(title: "알림", message: "게시물 수정 기능은 준비 중입니다.")
    }
    
    private func deletePost() {
        let alert = UIAlertController(title: "게시물 삭제", message: "정말 삭제하시겠습니까?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            guard let self = self, let userId = UserDefaults.standard.object(forKey: "userId") as? Int else { return }
            
            // 삭제 API 호출
            NetworkManager.shared.deletePost(postId: self.post.id, userId: userId) { [weak self] result in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        // 삭제 성공 시 이전 화면으로 이동
                        self.showToast(message: "게시물이 삭제되었습니다.")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.navigationController?.popViewController(animated: true)
                        }
                    case .failure(let error):
                        self.showAlert(title: "오류", message: error.localizedDescription)
                    }
                }
            }
        })
        
        present(alert, animated: true)
    }
    
    private func reportPost() {
        showAlert(title: "신고하기", message: "신고 기능은 준비 중입니다.")
    }
    
    // MARK: - Helper Methods
    private func isLoggedIn() -> Bool {
        return UserDefaults.standard.string(forKey: "userToken") != nil
    }
    
    private func isMyPost() -> Bool {
        guard let userId = UserDefaults.standard.object(forKey: "userId") as? Int,
              let postUserId = post.user?.id else {
            return false
        }
        return userId == postUserId
    }
    
    private func showLoginRequiredAlert() {
        let alert = UIAlertController(
            title: "로그인 필요",
            message: "이 기능을 사용하려면 로그인이 필요합니다.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "로그인", style: .default) { [weak self] _ in
            self?.navigateToLogin()
        })
        
        present(alert, animated: true)
    }
    
    private func navigateToLogin() {
        // 로그인 화면으로 이동
        let loginVC = LoginViewController()
        let navigationController = UINavigationController(rootViewController: loginVC)
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    private func showToast(message: String) {
        let toastLabel = UILabel()
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        toastLabel.textColor = .white
        toastLabel.textAlignment = .center
        toastLabel.font = UIFont.systemFont(ofSize: 14)
        toastLabel.text = message
        toastLabel.alpha = 0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds = true
        toastLabel.numberOfLines = 0
        
        // 크기 계산 및 위치 지정
        let maxWidth = view.frame.width - 40
        // 고정 높이 사용
        let height: CGFloat = 60
        
        toastLabel.frame = CGRect(x: 20,
                                  y: view.frame.height - height - 90,  // 하단에서 위로
                                  width: maxWidth,
                                  height: height)
        
        view.addSubview(toastLabel)
        
        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseIn, animations: {
            toastLabel.alpha = 1.0
        }, completion: { _ in
            UIView.animate(withDuration: 0.5, delay: 2.0, options: .curveEaseOut, animations: {
                toastLabel.alpha = 0.0
            }, completion: { _ in
                toastLabel.removeFromSuperview()
            })
        })
    }
    
    private func formatPrice(_ price: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: price)).map { "₩\($0)" } ?? "₩\(price)"
    }
    
    // 이미지 로딩 기능
    private func loadImage(from url: URL, to imageView: UIImageView) {
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("Error loading image: \(error.localizedDescription)")
                return
            }
            
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    imageView.image = image
                }
            }
        }.resume()
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension PostDetailViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return post.imageUrls?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PostImageCell", for: indexPath) as? PostImageCell,
              let imageUrls = post.imageUrls, indexPath.item < imageUrls.count else {
            return UICollectionViewCell()
        }
        
        // 이미지 URL 생성
        let baseURL = "http://localhost:8080/images/"
        let imageURLString = baseURL + imageUrls[indexPath.item]
        
        if let url = URL(string: imageURLString) {
            cell.loadImage(from: url)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == imageCollectionView {
            let pageWidth = scrollView.frame.width
            let currentPage = Int((scrollView.contentOffset.x + pageWidth / 2) / pageWidth)
            pageControl.currentPage = currentPage
        }
    }
}

// MARK: - PostImageCell
class PostImageCell: UICollectionViewCell {
    
    // MARK: - Properties
       private let imageView: UIImageView = {
           let imageView = UIImageView()
           imageView.contentMode = .scaleAspectFit
           imageView.clipsToBounds = true
           imageView.backgroundColor = .systemGray6
           imageView.translatesAutoresizingMaskIntoConstraints = false
           return imageView
       }()
       
       private let activityIndicator: UIActivityIndicatorView = {
           let indicator = UIActivityIndicatorView(style: .medium)
           indicator.hidesWhenStopped = true
           indicator.translatesAutoresizingMaskIntoConstraints = false
           return indicator
       }()
       
       // MARK: - Initializer
       override init(frame: CGRect) {
           super.init(frame: frame)
           setupViews()
       }
       
       required init?(coder: NSCoder) {
           fatalError("init(coder:) has not been implemented")
       }
       
       // MARK: - Setup
       private func setupViews() {
           contentView.addSubview(imageView)
           contentView.addSubview(activityIndicator)
           
           NSLayoutConstraint.activate([
               imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
               imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
               imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
               imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
               
               activityIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
               activityIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
           ])
       }
       
       // MARK: - Public Methods
       func loadImage(from url: URL) {
           // 이미지 로딩 전 초기화
           imageView.image = nil
           activityIndicator.startAnimating()
           
           URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
               DispatchQueue.main.async {
                   self?.activityIndicator.stopAnimating()
                   
                   if let error = error {
                       print("Error loading image: \(error.localizedDescription)")
                       return
                   }
                   
                   if let data = data, let image = UIImage(data: data) {
                       self?.imageView.image = image
                   }
               }
           }.resume()
       }
       
       override func prepareForReuse() {
           super.prepareForReuse()
           imageView.image = nil
           activityIndicator.stopAnimating()
       }
    }
