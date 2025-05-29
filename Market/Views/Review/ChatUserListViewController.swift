//
//  ChatUserListViewController.swift
//  Market
//
//  Created by 장동혁 on 5/30/25.
//

import UIKit

// MARK: - ChatUser Model
struct ChatUser: Codable {
    let userId: Int
    let nickname: String
    let profileImageUrl: String?
    let email: String?
    let lastChatDate: Date?
    let postId: Int? // 거래한 게시물 ID 추가
    
    enum CodingKeys: String, CodingKey {
        case userId, nickname, profileImageUrl, email, lastChatDate, postId
    }
    
    init(userId: Int, nickname: String, profileImageUrl: String?, email: String?, lastChatDate: Date?, postId: Int? = nil) {
        self.userId = userId
        self.nickname = nickname
        self.profileImageUrl = profileImageUrl
        self.email = email
        self.lastChatDate = lastChatDate
        self.postId = postId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userId = try container.decode(Int.self, forKey: .userId)
        nickname = try container.decode(String.self, forKey: .nickname)
        profileImageUrl = try container.decodeIfPresent(String.self, forKey: .profileImageUrl)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        postId = try container.decodeIfPresent(Int.self, forKey: .postId)
        
        if let lastChatTimestamp = try container.decodeIfPresent(Double.self, forKey: .lastChatDate) {
            lastChatDate = Date(timeIntervalSince1970: lastChatTimestamp)
        } else {
            lastChatDate = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userId, forKey: .userId)
        try container.encode(nickname, forKey: .nickname)
        try container.encodeIfPresent(profileImageUrl, forKey: .profileImageUrl)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(postId, forKey: .postId)
        
        if let lastChatDate = lastChatDate {
            try container.encode(lastChatDate.timeIntervalSince1970, forKey: .lastChatDate)
        }
    }
}

// MARK: - ChatUserListViewController
class ChatUserListViewController: UIViewController {
    
    // MARK: - Properties
    private var chatUsers: [ChatUser] = []
    private var isLoading = false
    
    // MARK: - UI Components
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "리뷰할 사용자 선택"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .white
        tableView.separatorStyle = .singleLine
        tableView.rowHeight = 80
        return tableView
    }()
    
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "채팅한 사용자가 없습니다"
        label.font = .systemFont(ofSize: 16)
        label.textColor = .gray
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewController()
        setupNavigationBar()
        setupUI()
        setupTableView()
        loadChatUsers()
    }
    
    // MARK: - Setup Methods
    private func setupViewController() {
        view.backgroundColor = .white
    }
    
    private func setupNavigationBar() {
        title = "리뷰할 사용자"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(addUserTapped)
        )
    }
    
    private func setupUI() {
        [titleLabel, tableView, emptyLabel].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ChatUserTableViewCell.self, forCellReuseIdentifier: "ChatUserCell")
    }
    
    // MARK: - Data Loading
    private func loadChatUsers() {
        guard !isLoading else { return }
        guard UserDefaults.standard.string(forKey: "userToken") != nil else {
            showAlert(message: "로그인이 필요합니다.")
            return
        }
        
        isLoading = true
        showLoadingIndicator()
        
        let savedUsers = loadChatUsersFromLocalStorage()
        
        // 더미 데이터 제거 - 저장된 사용자만 표시
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.handleUsersLoaded(savedUsers, shouldSave: false)
        }
    }
    
    private func handleUsersLoaded(_ users: [ChatUser], shouldSave: Bool) {
        hideLoadingIndicator()
        isLoading = false
        chatUsers = users
        updateUI()
        
        if shouldSave {
            users.forEach { saveChatUserToLocalStorage($0) }
        }
    }
    
    // MARK: - Local Storage
    private func loadChatUsersFromLocalStorage() -> [ChatUser] {
        guard let savedData = UserDefaults.standard.data(forKey: "chatUsers"),
              let savedUsers = try? JSONDecoder().decode([ChatUser].self, from: savedData) else {
            return []
        }
        return savedUsers
    }
    
    private func saveChatUserToLocalStorage(_ user: ChatUser) {
        var existingUsers = loadChatUsersFromLocalStorage()
        
        if !existingUsers.contains(where: { $0.userId == user.userId }) {
            existingUsers.append(user)
            
            if let encodedData = try? JSONEncoder().encode(existingUsers) {
                UserDefaults.standard.set(encodedData, forKey: "chatUsers")
            }
        }
    }
    
    // MARK: - UI Updates
    private func updateUI() {
        if chatUsers.isEmpty {
            emptyLabel.isHidden = false
            tableView.isHidden = true
        } else {
            emptyLabel.isHidden = true
            tableView.isHidden = false
            tableView.reloadData()
        }
    }
    
    // MARK: - Actions
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func addUserTapped() {
        let alert = UIAlertController(title: "사용자 추가", message: "리뷰할 사용자를 추가하세요", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "사용자 이름"
        }
        
        alert.addTextField { textField in
            textField.placeholder = "이메일 (선택사항)"
            textField.keyboardType = .emailAddress
        }
        
        alert.addTextField { textField in
            textField.placeholder = "게시물 ID (거래한 상품의 ID)"
            textField.keyboardType = .numberPad
        }
        
        let addAction = UIAlertAction(title: "추가", style: .default) { [weak self] _ in
            guard let nickname = alert.textFields?[0].text, !nickname.isEmpty else { return }
            let email = alert.textFields?[1].text
            let postIdText = alert.textFields?[2].text ?? ""
            let postId = Int(postIdText) ?? 1 // 기본값 1
            
            let newUser = ChatUser(
                userId: Int.random(in: 200...999),
                nickname: nickname,
                profileImageUrl: nil,
                email: email?.isEmpty == true ? nil : email,
                lastChatDate: Date(),
                postId: postId
            )
            
            self?.saveChatUserToLocalStorage(newUser)
            self?.chatUsers.append(newUser)
            self?.updateUI()
        }
        
        alert.addAction(addAction)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        
        present(alert, animated: true)
    }
    
    // MARK: - Helper Methods
    private func showLoadingIndicator() {
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = view.center
        activityIndicator.tag = 999
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
        view.isUserInteractionEnabled = false
    }
    
    private func hideLoadingIndicator() {
        if let activityIndicator = view.viewWithTag(999) as? UIActivityIndicatorView {
            activityIndicator.stopAnimating()
            activityIndicator.removeFromSuperview()
        }
        view.isUserInteractionEnabled = true
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension ChatUserListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatUserCell", for: indexPath) as! ChatUserTableViewCell
        let user = chatUsers[indexPath.row]
        cell.configure(with: user)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ChatUserListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedUser = chatUsers[indexPath.row]
        let reviewDetailVC = ReviewDetailViewController()
        reviewDetailVC.targetUserId = selectedUser.userId
        reviewDetailVC.targetUserName = selectedUser.nickname
        reviewDetailVC.postId = selectedUser.postId ?? 1 // postId 전달 (기본값 1)
        
        navigationController?.pushViewController(reviewDetailVC, animated: true)
    }
}

// MARK: - ChatUserTableViewCell
class ChatUserTableViewCell: UITableViewCell {
    
    // MARK: - UI Components
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person.circle.fill")
        imageView.tintColor = .systemGray4
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 25
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let nicknameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .black
        return label
    }()
    
    private let emailLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .gray
        return label
    }()
    
    private let arrowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "chevron.right")
        imageView.tintColor = .gray
        return imageView
    }()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        [profileImageView, nicknameLabel, emailLabel, arrowImageView].forEach {
            contentView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            profileImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 50),
            profileImageView.heightAnchor.constraint(equalToConstant: 50),
            
            nicknameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            nicknameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            nicknameLabel.trailingAnchor.constraint(equalTo: arrowImageView.leadingAnchor, constant: -12),
            
            emailLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            emailLabel.topAnchor.constraint(equalTo: nicknameLabel.bottomAnchor, constant: 4),
            emailLabel.trailingAnchor.constraint(equalTo: arrowImageView.leadingAnchor, constant: -12),
            
            arrowImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            arrowImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            arrowImageView.widthAnchor.constraint(equalToConstant: 20),
            arrowImageView.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    // MARK: - Configuration
    func configure(with user: ChatUser) {
        nicknameLabel.text = user.nickname
        emailLabel.text = user.email ?? ""
        loadProfileImage(profileImageUrl: user.profileImageUrl)
    }
    
    private func loadProfileImage(profileImageUrl: String?) {
        guard let profileImageUrl = profileImageUrl,
              !profileImageUrl.isEmpty,
              let url = URL(string: "https://hanlumi.co.kr/images/profile/\(profileImageUrl)") else {
            profileImageView.image = UIImage(systemName: "person.circle.fill")
            profileImageView.tintColor = .systemGray4
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self?.profileImageView.image = image
                    self?.profileImageView.tintColor = .clear
                }
            } else {
                DispatchQueue.main.async {
                    self?.profileImageView.image = UIImage(systemName: "person.circle.fill")
                    self?.profileImageView.tintColor = .systemGray4
                }
            }
        }.resume()
    }
}
