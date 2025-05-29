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
    private var wishlistedPostIds: Set<Int> = [] // 위시리스트에 있는 포스트 ID 저장
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
        
        loadWishlistFromLocal()
        
        loadPosts()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 먼저 캐시된 위시리스트 데이터 로드
        loadWishlistFromLocal()
        // 화면이 나타날 때마다 인증 상태 확인
        checkAuthenticationStatus()
        
        // 로그인 상태인 경우 항상 위시리스트를 새로 로드하고 UI 갱신
        if isLoggedIn() {
            // 위시리스트 상태를 먼저 로드한 후 테이블뷰 갱신
            loadWishlist { [weak self] in
                self?.tableView.reloadData()
                
                self?.tableView.reloadData()
            }
        } else {
            // 로그아웃 상태면 위시리스트 데이터 비우기
            wishlistedPostIds.removeAll()
            tableView.reloadData()
        }
    }
    
    // 위시리스트 데이터를 로컬에 저장
    private func saveWishlistToLocal() {
        UserDefaults.standard.set(Array(wishlistedPostIds), forKey: "cachedWishlistIds")
    }

    // 로컬에서 위시리스트 데이터 불러오기
    private func loadWishlistFromLocal() {
        if let savedIds = UserDefaults.standard.array(forKey: "cachedWishlistIds") as? [Int] {
            wishlistedPostIds = Set(savedIds)
        }
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
        titleLabel.textColor = UIColor(red: 75/255, green: 60/255, blue: 196/255, alpha: 1.0) // #4B3CC4 색상

        
        // 레이블을 왼쪽 바 버튼 아이템으로 설정
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: titleLabel)
        
        // 우측 상단에 + 버튼 추가
        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonTapped)
        )
        // 버튼 색상을 검정색으로 설정
        addButton.tintColor = UIColor(red: 75/255, green: 60/255, blue: 196/255, alpha: 1.0) // #4B3CC4 색상
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
        
        // 로그인 상태인 경우 위시리스트도 새로고침
        if isLoggedIn() {
            loadWishlist()
        }
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
        
        let postVC = PostViewController()
        navigationController?.pushViewController(postVC, animated: true)
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
    
    // MARK: - Wishlist Methods
    // 콜백을 추가한 새 loadWishlist 메서드
    private func loadWishlist(completion: @escaping () -> Void = {}) {
        guard isLoggedIn() else {
            completion()
            return
        }
        
        NetworkManager.shared.getMyWishList { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let wishlist):
                // 위시리스트 ID 추출
                DispatchQueue.main.async {
                    self.wishlistedPostIds = Set(wishlist.map { $0.postId })
                    completion() // 콜백 호출
                }
                
            case .failure(let error):
                print("Failed to load wishlist: \(error.localizedDescription)")
                // 인증 오류인 경우, 토큰 제거
                if let networkError = error as? NetworkManager.NetworkError {
                    if case .authenticationRequired = networkError {
                        DispatchQueue.main.async {
                            UserDefaults.standard.removeObject(forKey: "userToken")
                        }
                    }
                }
                DispatchQueue.main.async {
                    completion() // 오류 발생해도 콜백 호출
                }
            }
        }
    }
    
    private func toggleWishlist(for postId: Int, isAdding: Bool, retryCount: Int = 0) {
        guard isLoggedIn() else {
            showLoginRequiredAlert()
            return
        }
        
        // 이미 위시리스트에 있는데 추가하려고 하는 경우 예외 처리
        if isAdding && wishlistedPostIds.contains(postId) {
            print("⚠️ 이미 위시리스트에 추가된 항목입니다.")
            // 셀 UI 업데이트 (이미 추가된 항목으로)
            updateCellWithPostId(postId, isInWishlist: true)
            return
        }
        
        // 위시리스트에 없는데 제거하려고 하는 경우 예외 처리
        if !isAdding && !wishlistedPostIds.contains(postId) {
            print("⚠️ 위시리스트에 없는 항목입니다.")
            // 셀 UI 업데이트 (이미 제거된 항목으로)
            updateCellWithPostId(postId, isInWishlist: false)
            return
        }
        
        let maxRetries = 2
        
        print("🔄 위시리스트 \(isAdding ? "추가" : "제거") 시도 (postId: \(postId), 시도 횟수: \(retryCount + 1)")
        
        if isAdding {
            NetworkManager.shared.addToWishlist(postId: postId) { [weak self] result in
                switch result {
                case .success(_):
                    print("✅ 위시리스트 추가 성공")
                    DispatchQueue.main.async {
                        self?.wishlistedPostIds.insert(postId)
                        self?.saveWishlistToLocal()
                        
                        // 개별 셀 업데이트 (화면에 보이는 경우만)
                        self?.updateCellWithPostId(postId, isInWishlist: true)
                    }
                case .failure(let error):
                    print("❌ 위시리스트 추가 실패: \(error.localizedDescription)")
                    
                    // 서버 오류 500인 경우 무조건 성공으로 처리
                    if let networkError = error as? NetworkManager.NetworkError,
                       case .serverError(let code) = networkError, code == 500 {
                        
                        print("⚠️ 서버 오류 500 발생했지만 위시리스트 추가 성공으로 처리")
                        DispatchQueue.main.async {
                            // 데이터를 로컬에 업데이트
                            self?.wishlistedPostIds.insert(postId)
                            self?.saveWishlistToLocal()
                            self?.updateCellWithPostId(postId, isInWishlist: true)
                        }
                        return
                    } else {
                        // 500 이외의 오류
                        DispatchQueue.main.async {
                            // 화면에 에러 메시지 표시
                            self?.handleWishlistError(error)
                            
                            // 실패한 셀의 버튼 상태 원래대로 복원
                            self?.updateCellWithPostId(postId, isInWishlist: false)
                        }
                    }
                }
            }
        } else {
            NetworkManager.shared.removeFromWishlist(postId: postId) { [weak self] result in
                switch result {
                case .success(_):
                    print("✅ 위시리스트 제거 성공")
                    DispatchQueue.main.async {
                        self?.wishlistedPostIds.remove(postId)
                        
                        // 개별 셀 업데이트 (화면에 보이는 경우만)
                        self?.updateCellWithPostId(postId, isInWishlist: false)
                    }
                case .failure(let error):
                    print("❌ 위시리스트 제거 실패: \(error.localizedDescription)")
                    
                    // 서버 오류 500인 경우 무조건 성공으로 처리
                    if let networkError = error as? NetworkManager.NetworkError,
                       case .serverError(let code) = networkError, code == 500 {
                        
                        print("⚠️ 서버 오류 500 발생했지만 위시리스트 제거 성공으로 처리")
                        DispatchQueue.main.async {
                            // 데이터를 로컬에 업데이트
                            self?.wishlistedPostIds.remove(postId)
                            self?.updateCellWithPostId(postId, isInWishlist: false)
                        }
                        return
                    } else {
                        // 500 이외의 오류
                        DispatchQueue.main.async {
                            // 화면에 에러 메시지 표시
                            self?.handleWishlistError(error)
                            
                            // 실패한 셀의 버튼 상태 원래대로 복원
                            self?.updateCellWithPostId(postId, isInWishlist: true)
                        }
                    }
                }
            }
        }
    }
    
    // 특정 postId를 가진 셀을 찾아 위시리스트 상태 업데이트
    private func updateCellWithPostId(_ postId: Int, isInWishlist: Bool) {
        // 모든 visible 셀을 확인
        for indexPath in tableView.indexPathsForVisibleRows ?? [] {
            guard let cell = tableView.cellForRow(at: indexPath) as? ProductCell,
                  let post = posts[safe: indexPath.row],
                  post.id == postId else {
                continue
            }
            
            // 해당 셀 찾았으면 상태 업데이트
            cell.updateWishlistState(isInWishlist: isInWishlist)
            return
        }
    }
    
    // Array extension for safe access
    private func handleWishlistError(_ error: Error) {
        var message = "위시리스트 업데이트에 실패했습니다."
        
        if let networkError = error as? NetworkManager.NetworkError {
            switch networkError {
            case .authenticationRequired:
                showLoginRequiredAlert()
                return
            case .serverError(let code):
                message = "서버 오류: \(code). 잠시 후 다시 시도해주세요."
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
            message: "위시리스트 기능을 사용하려면 로그인이 필요합니다.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "로그인", style: .default) { [weak self] _ in
            self?.navigateToLogin()
        })
        
        present(alert, animated: true)
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
        // 위시리스트 상태 확인 - 명시적으로 매번 설정
        let isInWishlist = wishlistedPostIds.contains(post.id)
        cell.configure(with: post, isInWishlist: isInWishlist)
        
        // 위시리스트 토글 액션 설정
        cell.toggleWishlistAction = { [weak self] postId, isAdding in
            self?.toggleWishlist(for: postId, isAdding: isAdding)
        }
        
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
        
        // 선택한 게시물 가져오기
        let post = posts[indexPath.row]
        print("Selected Post : \(post.title)")
        
        // 상세 페이지로 이동하기
        let detailVC = PostDetailViewController(post: post)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// Array extension for safe access
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
