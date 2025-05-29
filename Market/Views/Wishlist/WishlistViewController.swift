//
//  WishlistViewController.swift
//  Market
//
//  Created by 장동혁 on 3/13/25.
//

import UIKit

class WishlistViewController: UIViewController {
    
    // MARK: - Properties
    private var wishlistItems: [Wishlist] = []
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
    
    private let emptyView: UIView = {
        let view = UIView()
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let emptyImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "heart.slash")
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemGray3
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "위시리스트가 비어있습니다."
        label.textAlignment = .center
        label.textColor = .systemGray
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupNavigationBar()
        setupViews()
        setupTableView()
        setupRefreshControl()
        setupEmptyView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadWishlist()
    }
    
    // MARK: - Setup Methods
    private func setupNavigationBar() {
        title = "내 위시리스트"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // 뒤로가기 버튼 커스터마이징
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        backButton.tintColor = .black
        navigationItem.leftBarButtonItem = backButton
    }
    
    private func setupViews() {
        view.addSubview(tableView)
        view.addSubview(activityIndicator)
        view.addSubview(emptyView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            emptyView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyView.widthAnchor.constraint(equalToConstant: 200),
            emptyView.heightAnchor.constraint(equalToConstant: 200)
        ])
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func setupRefreshControl() {
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    private func setupEmptyView() {
        emptyView.addSubview(emptyImageView)
        emptyView.addSubview(emptyLabel)
        
        NSLayoutConstraint.activate([
            emptyImageView.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            emptyImageView.topAnchor.constraint(equalTo: emptyView.topAnchor),
            emptyImageView.widthAnchor.constraint(equalToConstant: 80),
            emptyImageView.heightAnchor.constraint(equalToConstant: 80),
            
            emptyLabel.topAnchor.constraint(equalTo: emptyImageView.bottomAnchor, constant: 16),
            emptyLabel.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: emptyView.leadingAnchor),
            emptyLabel.trailingAnchor.constraint(equalTo: emptyView.trailingAnchor)
        ])
    }
    
    // MARK: - Actions
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func refreshData() {
        loadWishlist()
    }
    
    // MARK: - Data Loading
    private func loadWishlist() {
        guard !isLoading else {
            refreshControl.endRefreshing()
            return
        }
        
        guard isLoggedIn() else {
            showLoginRequiredAlert()
            refreshControl.endRefreshing()
            return
        }
        
        isLoading = true
        activityIndicator.startAnimating()
        
        NetworkManager.shared.getMyWishList { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                self.activityIndicator.stopAnimating()
                self.refreshControl.endRefreshing()
                
                switch result {
                case .success(let wishlist):
                    self.wishlistItems = wishlist
                    self.tableView.reloadData()
                    self.updateEmptyState()
                    
                case .failure(let error):
                    self.handleError(error)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func isLoggedIn() -> Bool {
        return UserDefaults.standard.string(forKey: "userToken") != nil
    }
    
    private func updateEmptyState() {
        if wishlistItems.isEmpty {
            emptyView.isHidden = false
            tableView.isHidden = true
        } else {
            emptyView.isHidden = true
            tableView.isHidden = false
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
            case .authenticationRequired:
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
    
    private func showLoginRequiredAlert() {
        let alert = UIAlertController(
            title: "로그인 필요",
            message: "위시리스트를 확인하려면 로그인이 필요합니다.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "로그인", style: .default) { [weak self] _ in
            self?.navigateToLogin()
        })
        
        present(alert, animated: true)
    }
    
    private func navigateToLogin() {
        UserDefaults.standard.removeObject(forKey: "userToken")
        
        let loginVC = LoginViewController()
        let navigationController = UINavigationController(rootViewController: loginVC)
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true)
    }
    
    // MARK: - Wishlist Actions
    private func removeFromWishlist(at indexPath: IndexPath) {
        guard isLoggedIn() else {
            showLoginRequiredAlert()
            return
        }
        
        let item = wishlistItems[indexPath.row]
        
        NetworkManager.shared.removeFromWishlist(postId: item.postId) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // 성공적으로 제거됨
                    self.wishlistItems.remove(at: indexPath.row)
                    self.tableView.deleteRows(at: [indexPath], with: .fade)
                    self.updateEmptyState()
                    
                case .failure(let error):
                    print("위시리스트 제거 실패: \(error.localizedDescription)")
                    let message = (error as? NetworkManager.NetworkError)?.errorDescription ?? "위시리스트에서 제거하지 못했습니다."
                    
                    let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "확인", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension WishlistViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return wishlistItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ProductCell", for: indexPath) as? ProductCell else {
            return UITableViewCell()
        }
        
        let item = wishlistItems[indexPath.row]
        
        // Post가 있는 경우 해당 정보로 셀 구성
        if let post = item.post {
            cell.configure(with: post, isInWishlist: true)
            
            // 위시리스트 토글 액션 설정
            cell.toggleWishlistAction = { [weak self] postId, isAdding in
                guard let self = self else { return }
                
                if !isAdding {
                    // 위시리스트에서 제거
                    self.removeFromWishlist(at: indexPath)
                }
            }
        } else {
            // Post 정보가 없는 경우 postId로 포스트 정보 다시 가져오기
            NetworkManager.shared.fetchPost(id: item.postId) { [weak self, weak cell] result in
                guard let self = self, let cell = cell else { return }
                
                DispatchQueue.main.async {
                    switch result {
                    case .success(let post):
                        // 셀 업데이트
                        cell.configure(with: post, isInWishlist: true)
                        
                        // 위시리스트 아이템의 Post 정보 업데이트 (불가능하면 삭제)
                        if indexPath.row < self.wishlistItems.count {
                            // 새 Wishlist 아이템 생성 (Post 정보 포함)
                            let updatedItem = Wishlist(
                                id: item.id,
                                userId: item.userId,
                                postId: item.postId,
                                post: post
                            )
                            self.wishlistItems[indexPath.row] = updatedItem
                        }
                        
                    case .failure:
                        // 포스트 정보를 가져오지 못한 경우 기본 정보만 표시
                        cell.configureFallback(postId: item.postId)
                    }
                }
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = wishlistItems[indexPath.row]
        
        // Post 정보가 있는 경우 바로 상세 페이지로 이동
        if let post = item.post {
            let detailVC = PostDetailViewController(post: post)
            navigationController?.pushViewController(detailVC, animated: true)
        } else {
            // Post 정보가 없는 경우, 서버에서 가져온 후 이동
            activityIndicator.startAnimating()
            
            NetworkManager.shared.fetchPost(id: item.postId) { [weak self] result in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    
                    switch result {
                    case .success(let post):
                        let detailVC = PostDetailViewController(post: post)
                        self.navigationController?.pushViewController(detailVC, animated: true)
                        
                    case .failure(let error):
                        print("포스트 가져오기 실패: \(error.localizedDescription)")
                        self.showAlert(message: "상품 정보를 불러올 수 없습니다.")
                    }
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "삭제") { [weak self] (_, _, completionHandler) in
            self?.removeFromWishlist(at: indexPath)
            completionHandler(true)
        }
        deleteAction.backgroundColor = .systemRed
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Extension for ProductCell
// 이 extension은 ProductCell.swift 파일에 추가해야 합니다
/*
extension ProductCell {
    func configureFallback(postId: Int) {
        self.postId = postId
        
        titleLabel.text = "상품 정보를 불러오는 중..."
        priceLabel.text = "가격 정보 없음"
        placeLabel.text = "위치 정보 없음"
        productImageView.image = UIImage(systemName: "photo")
        productImageView.tintColor = .systemGray3
        
        // 위시리스트 상태는 기본적으로 true (위시리스트 화면이므로)
        isInWishlist = true
        updateWishlistButtonAppearance()
    }
}
*/
