// ChatViewController.swift - 실제 서버 통신용 수정

import UIKit

class ChatViewController: UIViewController {
    
    // MARK: - Properties
    private var chatRooms: [ChatRoomModel] = []
    private var isLoading = false
    private let refreshControl = UIRefreshControl()
    private var lastRefreshTime: Date?
    
    // MARK: - UI Components
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .white
        tableView.separatorStyle = .singleLine
        tableView.register(ChatRoomCell.self, forCellReuseIdentifier: "ChatRoomCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private let emptyStateView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    private let emptyStateImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "bubble.left.and.bubble.right")
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .lightGray
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "새로운 채팅을 시작해보세요"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 18)
        label.textColor = .darkGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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
        setupEmptyStateView()
        setupRefreshControl()
        
        loadChatRooms()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        customTabBar.updateButtonColors(customTabBar.chatButton)
        
        checkAuthenticationStatus()
        
        if isLoggedIn() {
            refreshChatRoomsIfNeeded()
        }
    }
    
    // MARK: - Setup Methods
    private func setupNavigationBar() {
        navigationItem.hidesBackButton = true
        navigationItem.title = nil
        
        let titleLabel = UILabel()
        titleLabel.text = "채팅"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .black
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: titleLabel)
    }
    
    private func refreshChatRoomsIfNeeded() {
        let now = Date()
        if let lastRefresh = lastRefreshTime,
           now.timeIntervalSince(lastRefresh) < 30 {
            print("ℹ️ 최근에 새로고침했으므로 스킵")
            return
        }
        
        refreshChatRooms()
    }
    
    private func setupViews() {
        view.addSubview(tableView)
        view.addSubview(activityIndicator)
        view.addSubview(emptyStateView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -90),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            emptyStateView.heightAnchor.constraint(equalToConstant: 200)
        ])
    }
    
    private func setupEmptyStateView() {
        emptyStateView.addSubview(emptyStateImageView)
        emptyStateView.addSubview(emptyStateLabel)
        
        NSLayoutConstraint.activate([
            emptyStateImageView.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyStateImageView.topAnchor.constraint(equalTo: emptyStateView.topAnchor),
            emptyStateImageView.widthAnchor.constraint(equalToConstant: 80),
            emptyStateImageView.heightAnchor.constraint(equalToConstant: 80),
            
            emptyStateLabel.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyStateLabel.topAnchor.constraint(equalTo: emptyStateImageView.bottomAnchor, constant: 16),
            emptyStateLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor),
            emptyStateLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor)
        ])
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func setupRefreshControl() {
        refreshControl.addTarget(self, action: #selector(refreshChatRooms), for: .valueChanged)
        tableView.refreshControl = refreshControl
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
        
        customTabBar.didTapButton = { [weak self] button in
            switch button {
            case self?.customTabBar.homeButton:
                self?.navigationController?.popToRootViewController(animated: false)
            case self?.customTabBar.chatButton:
                print("Chat - Already on this page")
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
            showLoginRequiredView()
        } else {
            emptyStateView.isHidden = true
            tableView.isHidden = false
            
            if chatRooms.isEmpty {
                loadChatRooms()
            }
        }
    }
    
    private func showLoginRequiredView() {
        emptyStateLabel.text = "로그인이 필요한 서비스입니다"
        emptyStateImageView.image = UIImage(systemName: "person.crop.circle.badge.exclamationmark")
        
        // 기존 로그인 버튼 제거
        for subview in emptyStateView.subviews {
            if subview is UIButton {
                subview.removeFromSuperview()
            }
        }
        
        // 로그인 버튼 추가
        let loginButton = UIButton(type: .system)
        loginButton.setTitle("로그인", for: .normal)
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.backgroundColor = .systemBlue
        loginButton.layer.cornerRadius = 8
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        loginButton.addTarget(self, action: #selector(navigateToLogin), for: .touchUpInside)
        
        emptyStateView.addSubview(loginButton)
        
        NSLayoutConstraint.activate([
            loginButton.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            loginButton.topAnchor.constraint(equalTo: emptyStateLabel.bottomAnchor, constant: 16),
            loginButton.widthAnchor.constraint(equalToConstant: 120),
            loginButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        emptyStateView.isHidden = false
        tableView.isHidden = true
    }
    
    private func showEmptyStateIfNeeded() {
        if chatRooms.isEmpty {
            emptyStateLabel.text = "새로운 채팅을 시작해보세요"
            emptyStateImageView.image = UIImage(systemName: "bubble.left.and.bubble.right")
            
            // 기존에 로그인 버튼이 있으면 제거
            for subview in emptyStateView.subviews {
                if subview is UIButton {
                    subview.removeFromSuperview()
                }
            }
            
            emptyStateView.isHidden = false
        } else {
            emptyStateView.isHidden = true
        }
    }
    
    // MARK: - Actions
    @objc private func refreshChatRooms() {
        lastRefreshTime = Date()
        loadChatRooms()
    }
    
    @objc private func navigateToLogin() {
        let loginVC = LoginViewController()
        let navigationController = UINavigationController(rootViewController: loginVC)
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true)
    }
    
    // MARK: - API Calls
    private func loadChatRooms() {
        guard !isLoading, isLoggedIn() else {
            refreshControl.endRefreshing()
            return
        }
        
        isLoading = true
        
        if chatRooms.isEmpty {
            activityIndicator.startAnimating()
        }
        
        NetworkManager.shared.getChatRooms { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                self.activityIndicator.stopAnimating()
                self.refreshControl.endRefreshing()
                
                switch result {
                case .success(let chatRoomResponses):
                    let newChatRooms = chatRoomResponses.map { $0.toChatRoomModel() }
                    
                    // 채팅방 목록 변경 여부 확인을 단순화
                    var hasChanges = false
                    
                    if self.chatRooms.count != newChatRooms.count {
                        hasChanges = true
                    } else {
                        // 각 채팅방을 개별적으로 비교
                        for (index, oldRoom) in self.chatRooms.enumerated() {
                            let newRoom = newChatRooms[index]
                            
                            if oldRoom.id != newRoom.id || oldRoom.lastMessage != newRoom.lastMessage {
                                hasChanges = true
                                break
                            }
                        }
                    }
                    
                    if hasChanges {
                        self.chatRooms = newChatRooms
                        self.tableView.reloadData()
                    }
                    
                    self.showEmptyStateIfNeeded()
                    
                case .failure(let error):
                    print("채팅방 목록 로드 실패: \(error.localizedDescription)")
                    
                    if case .authenticationRequired = error {
                        self.showLoginRequiredView()
                    } else {
                        print("⚠️ 채팅방 목록 로드 실패하지만 기존 목록 유지")
                        
                        // 기존 목록이 비어있는 경우에만 empty state 표시
                        if self.chatRooms.isEmpty {
                            self.showEmptyStateIfNeeded()
                        }
                    }
                }
            }
        }
    }
    
    // 오류 알림 표시
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    // 채팅방 진입
    private func enterChatRoom(_ chatRoom: ChatRoomModel) {
        // 채팅 상세 화면으로 이동
        let chatDetailVC = ChatDetailViewController(
            chatRoomId: chatRoom.id,
            partnerName: chatRoom.partnerName,
            postTitle: chatRoom.postTitle
        )
        
        navigationController?.pushViewController(chatDetailVC, animated: true)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension ChatViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatRooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ChatRoomCell", for: indexPath) as? ChatRoomCell else {
            return UITableViewCell()
        }
        
        let chatRoom = chatRooms[indexPath.row]
        cell.configure(with: chatRoom)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let chatRoom = chatRooms[indexPath.row]
        enterChatRoom(chatRoom)
    }
}
