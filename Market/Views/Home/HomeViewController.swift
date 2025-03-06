//
//  HomeViewController.swift
//  Market
//
//  Created by 장동혁 on 1/20/25.
//

import UIKit

class HomeViewController: UIViewController {
    
    // MARK: - Properties
    private var posts: [Post] = []
    private var currentPage = 0
    private var isLastPage = false
    private var isLoading = false
    private let refreshControl = UIRefreshControl()
    
    // MARK: - UI Components
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .white
        tableView.separatorStyle = .singleLine
        tableView.register(ProductCell.self, forCellReuseIdentifier: "ProductCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private let customTabBar = CustomTabBar()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupNavigationBar()
        setupViews()
        setupTableView()
        setupTabBar()
        setupRefreshControl()
        
        loadPosts()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 화면이 나타날 때마다 인증 상태 확인
        checkAuthenticationStatus()
    }
    
    // MARK: - Setup Methods
    private func setupNavigationBar() {
        navigationItem.hidesBackButton = true
            
        // 기본 타이틀 제거
        navigationItem.title = nil
        
        // 왼쪽에 커스텀 레이블 추가
        let titleLabel = UILabel()
        titleLabel.text = "Home"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .black
        
        // 레이블을 왼쪽 바 버튼 아이템으로 설정
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: titleLabel)
        
        // 우측 상단에 + 버튼 추가
        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonTapped)
        )
        // 버튼 색상을 검정색으로 설정
        addButton.tintColor = .black
        navigationItem.rightBarButtonItem = addButton
    }
    
    private func setupRefreshControl() {
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    @objc private func refreshData() {
        // 처음부터 데이터 다시 로드
        posts.removeAll()
        currentPage = 0
        isLastPage = false
        loadPosts()
    }
    
    // MARK: - Actions
    @objc private func addButtonTapped() {
        // 게시물 작성 화면으로 이동
        print("Add button tapped - Navigate to post creation")
        
        // 로그인 상태 확인
        guard isLoggedIn() else {
            navigateToLogin()
            return
        }
        
        // TODO: PostCreationViewController 구현 후 아래 코드 주석 해제
        // let postCreationVC = PostCreationViewController()
        // navigationController?.pushViewController(postCreationVC, animated: true)
        
        // 임시 알림 - 실제 구현 시 제거
        let alert = UIAlertController(
            title: "게시물 작성",
            message: "게시물 작성 화면으로 이동합니다.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    private func setupViews() {
        view.addSubview(tableView)
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -90),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func setupTabBar() {
        view.addSubview(customTabBar)
        customTabBar.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            customTabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customTabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customTabBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            customTabBar.heightAnchor.constraint(equalToConstant: 90)
        ])
        
        customTabBar.updateButtonColors(customTabBar.homeButton)
        
        customTabBar.didTapButton = { [weak self] button in
            switch button {
            case self?.customTabBar.homeButton:
                print("Home")
            case self?.customTabBar.chatButton:
                let chatVC = ChatViewController()
                self?.navigationController?.pushViewController(chatVC, animated: false)
            case self?.customTabBar.profileButton:
                let profileVC = ProfileViewController()
                self?.navigationController?.pushViewController(profileVC, animated: false)
            default:
                break
            }
        }
    }
    
    // MARK: - Helper Methods
    private func isLoggedIn() -> Bool {
        return UserDefaults.standard.string(forKey: "userToken") != nil
    }
    
    private func checkAuthenticationStatus() {
        if !isLoggedIn() {
            // 로그인 화면으로 이동 (선택적으로 자동 이동 설정 가능)
            // navigateToLogin()
            
            // 또는 임시 데이터 표시 (비로그인 상태에서 일부 기능 제한)
            print("User is not logged in")
        } else {
            print("User is logged in")
            if posts.isEmpty {
                loadPosts()
            }
        }
    }
    
    // MARK: - API Calls
    private func loadPosts() {
        guard !isLoading, !isLastPage else {
            refreshControl.endRefreshing()
            return
        }
        
        isLoading = true
        activityIndicator.startAnimating()
        
        NetworkManager.shared.fetchPosts(page: currentPage, size: 10) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                self.activityIndicator.stopAnimating()
                self.refreshControl.endRefreshing()
                
                switch result {
                case .success(let pageResponse):
                    self.posts.append(contentsOf: pageResponse.content)
                    self.isLastPage = pageResponse.last
                    self.currentPage += 1
                    self.tableView.reloadData()
                    
                    // 데이터가 없는 경우
                    if self.posts.isEmpty {
                        self.showEmptyStateIfNeeded()
                    }
                    
                case .failure(let error):
                    self.handleError(error)
                }
            }
        }
    }
    
    private func showEmptyStateIfNeeded() {
        if posts.isEmpty {
            let emptyLabel = UILabel()
            emptyLabel.text = "게시물이 없습니다."
            emptyLabel.textAlignment = .center
            emptyLabel.textColor = .gray
            tableView.backgroundView = emptyLabel
        } else {
            tableView.backgroundView = nil
        }
    }
    
    private func handleError(_ error: Error) {
        var message = "오류가 발생했습니다."
        
        if let networkError = error as? NetworkManager.NetworkError {
            switch networkError {
            case .serverError(let code):
                if code == 401 || code == 403 {
                    navigateToLogin()
                    return
                }
                message = "서버 오류: \(code)"
            case .invalidCredentials:
                navigateToLogin()
                return
            default:
                message = networkError.errorDescription ?? "오류가 발생했습니다."
            }
        }
        
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    private func navigateToLogin() {
        // 토큰 삭제
        UserDefaults.standard.removeObject(forKey: "userToken")
        
        // 로그인 화면으로 이동
        let loginVC = LoginViewController() // LoginViewController는 구현되어 있다고 가정
        let navigationController = UINavigationController(rootViewController: loginVC)
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ProductCell", for: indexPath) as? ProductCell else {
            return UITableViewCell()
        }
        
        let post = posts[indexPath.row]
        cell.configure(with: post)
        
        // Load more posts when user reaches the end
        if indexPath.row == posts.count - 1 && !isLoading && !isLastPage {
            loadPosts()
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let post = posts[indexPath.row]
        print("Selected post: \(post.title)")
        
        // TODO: Navigate to post detail view
        // let detailVC = PostDetailViewController(post: post)
        // navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - ProductCell
class ProductCell: UITableViewCell {
    private let productImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .lightGray
        imageView.layer.cornerRadius = 8
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let placeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .gray
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
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.addSubview(productImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(priceLabel)
        contentView.addSubview(placeLabel)
        contentView.addSubview(statusView)
        statusView.addSubview(statusLabel)
        
        NSLayoutConstraint.activate([
            productImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            productImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            productImageView.widthAnchor.constraint(equalToConstant: 80),
            productImageView.heightAnchor.constraint(equalToConstant: 80),
            
            titleLabel.leadingAnchor.constraint(equalTo: productImageView.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
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
            statusLabel.bottomAnchor.constraint(equalTo: statusView.bottomAnchor)
        ])
    }
    
    func configure(with post: Post) {
        titleLabel.text = post.title
        priceLabel.text = formatPrice(post.price)
        placeLabel.text = post.place ?? "위치 정보 없음"
        
        // 상태 설정
        configureStatus(post.status)
        
        // 첫 번째 이미지 로드
        if let imageUrls = post.imageUrls, !imageUrls.isEmpty {
            // 서버 URL과 이미지 경로 조합
            let baseURL = "http://localhost:8080/images/"
            let imageURLString = baseURL + imageUrls[0]
            
            if let imageUrl = URL(string: imageURLString) {
                loadImage(from: imageUrl)
            }
        } else {
            productImageView.image = nil
        }
    }
    
    private func formatPrice(_ price: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: price)).map { "\($0)원" } ?? "\(price)원"
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        productImageView.image = nil
        titleLabel.text = nil
        priceLabel.text = nil
        placeLabel.text = nil
        statusView.isHidden = false
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
