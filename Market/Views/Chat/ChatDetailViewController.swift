// ChatDetailViewController.swift - 실제 서버 통신

import UIKit

class ChatDetailViewController: UIViewController {
    
    // MARK: - Properties
    private let chatRoomId: Int
    private let partnerName: String
    private let postTitle: String
    
    private var messages: [Message] = []
    private var isLoading = false
    private var messageInputContainerBottomConstraint: NSLayoutConstraint!
    private var hasLoadedInitialMessages = false
    private var isViewAppearing = false
    
    // MARK: - UI Components
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private let messageInputContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let messageInputField: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.layer.borderColor = UIColor.lightGray.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 18
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        textView.isScrollEnabled = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    private let sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
        button.tintColor = .systemBlue
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let productInfoView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.borderColor = UIColor.lightGray.cgColor
        view.layer.borderWidth = 0.5
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let productImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .lightGray
        imageView.layer.cornerRadius = 6
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let productTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .black
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Initializers
    init(chatRoomId: Int, partnerName: String, postTitle: String) {
        self.chatRoomId = chatRoomId
        self.partnerName = partnerName
        self.postTitle = postTitle
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
        setupViews()
        setupTableView()
        setupMessageInput()
        setupKeyboardObservers()
        
        loadMessages()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isViewAppearing = true
        
        if !NetworkManager.shared.isWebSocketConnected() {
            reconnectWebSocketIfNeeded()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isViewAppearing = false
        
        setupWebSocketMessageHandler()
        
        if !NetworkManager.shared.isWebSocketConnected() {
            NetworkManager.shared.connectWebSocket(chatRoomId: chatRoomId) { [weak self] result in
                switch result {
                case .success:
                    print("✅ WebSocket 재연결 성공")
                case .failure(let error):
                    print("❌ WebSocket 재연결 실패: \(error)")
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup Methods
    private func setupNavigationBar() {
        title = partnerName
        
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        backButton.tintColor = .black
        navigationItem.leftBarButtonItem = backButton
        
        let menuButton = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis"),
            style: .plain,
            target: self,
            action: #selector(menuButtonTapped)
        )
        menuButton.tintColor = .black
        navigationItem.rightBarButtonItem = menuButton
    }
    
    private func setupWebSocketMessageHandler() {
        NetworkManager.shared.setWebSocketMessageHandler { [weak self] messageResponse in
            guard let self = self else { return }
            
            guard let message = messageResponse.toMessage() else { return }
            
            // 중복 메시지 체크 개선
            let isDuplicate = self.messages.contains { existingMessage in
                // ID 기반 중복 체크 (더 정확함)
                if existingMessage.id == message.id && existingMessage.id > 0 {
                    return true
                }
                
                // 내용 및 발신자 기반 중복 체크 (임시 메시지 처리용)
                return existingMessage.text == message.text &&
                       existingMessage.senderId == message.senderId &&
                       abs(existingMessage.timestamp.timeIntervalSince(message.timestamp)) < 5.0
            }
            
            if !isDuplicate {
                // 내가 보낸 메시지의 경우 임시 메시지 제거
                let myUserId = UserDefaults.standard.integer(forKey: "userId")
                if message.senderId == myUserId {
                    if let tempIndex = self.messages.firstIndex(where: {
                        $0.senderId == myUserId &&
                        $0.text == message.text &&
                        $0.id >= 10000 // 임시 ID 범위
                    }) {
                        self.messages.remove(at: tempIndex)
                        let tempIndexPath = IndexPath(row: tempIndex, section: 0)
                        self.tableView.deleteRows(at: [tempIndexPath], with: .none)
                    }
                }
                
                // 새 메시지 추가 (최신 메시지가 상단에 오도록)
                let insertIndex = self.messages.firstIndex { $0.timestamp < message.timestamp } ?? 0
                self.messages.insert(message, at: insertIndex)
                let indexPath = IndexPath(row: insertIndex, section: 0)
                self.tableView.insertRows(at: [indexPath], with: .bottom)
            }
        }
    }
    
    private func reconnectWebSocketIfNeeded() {
        // 이미 연결되어 있다면 재연결하지 않음
        guard !NetworkManager.shared.isWebSocketConnected() && hasLoadedInitialMessages else {
            return
        }
        
        NetworkManager.shared.connectWebSocket(chatRoomId: chatRoomId) { [weak self] result in
            switch result {
            case .success:
                print("✅ WebSocket 재연결 성공")
            case .failure(let error):
                print("❌ WebSocket 재연결 실패: \(error)")
                if case .authenticationRequired = error {
                    DispatchQueue.main.async {
                        self?.showAlert(title: "인증 오류", message: "다시 로그인해주세요")
                    }
                }
            }
        }
    }
    
    private func setupViews() {
        setupProductInfoView()
        
        view.addSubview(productInfoView)
        view.addSubview(tableView)
        view.addSubview(messageInputContainer)
        
        messageInputContainerBottomConstraint = messageInputContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        
        NSLayoutConstraint.activate([
            productInfoView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            productInfoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            productInfoView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            productInfoView.heightAnchor.constraint(equalToConstant: 60),
            
            tableView.topAnchor.constraint(equalTo: productInfoView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: messageInputContainer.topAnchor),
            
            messageInputContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            messageInputContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            messageInputContainerBottomConstraint
        ])
    }
    
    private func setupProductInfoView() {
        productInfoView.addSubview(productImageView)
        productInfoView.addSubview(productTitleLabel)
        
        NSLayoutConstraint.activate([
            productImageView.leadingAnchor.constraint(equalTo: productInfoView.leadingAnchor, constant: 16),
            productImageView.centerYAnchor.constraint(equalTo: productInfoView.centerYAnchor),
            productImageView.widthAnchor.constraint(equalToConstant: 40),
            productImageView.heightAnchor.constraint(equalToConstant: 40),
            
            productTitleLabel.leadingAnchor.constraint(equalTo: productImageView.trailingAnchor, constant: 12),
            productTitleLabel.centerYAnchor.constraint(equalTo: productInfoView.centerYAnchor),
            productTitleLabel.trailingAnchor.constraint(equalTo: productInfoView.trailingAnchor, constant: -16)
        ])
        
        productTitleLabel.text = postTitle
        productImageView.image = UIImage(systemName: "cart")
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(MessageCell.self, forCellReuseIdentifier: "SendMessageCell")
        tableView.register(MessageCell.self, forCellReuseIdentifier: "ReceiveMessageCell")
        tableView.transform = CGAffineTransform(scaleX: 1, y: -1)
    }
    
    private func setupMessageInput() {
        messageInputContainer.addSubview(messageInputField)
        messageInputContainer.addSubview(sendButton)
        
        let heightConstraint = messageInputContainer.heightAnchor.constraint(equalToConstant: 60)
        heightConstraint.priority = .defaultHigh
        
        NSLayoutConstraint.activate([
            heightConstraint,
            
            messageInputField.topAnchor.constraint(equalTo: messageInputContainer.topAnchor, constant: 10),
            messageInputField.leadingAnchor.constraint(equalTo: messageInputContainer.leadingAnchor, constant: 16),
            messageInputField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            messageInputField.bottomAnchor.constraint(equalTo: messageInputContainer.bottomAnchor, constant: -10),
            
            sendButton.trailingAnchor.constraint(equalTo: messageInputContainer.trailingAnchor, constant: -16),
            sendButton.centerYAnchor.constraint(equalTo: messageInputField.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 40),
            sendButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        messageInputField.delegate = self
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    // MARK: - WebSocket Setup
    private func setupWebSocket() {
        NetworkManager.shared.setWebSocketMessageHandler { [weak self] messageResponse in
            guard let self = self else { return }
            
            guard let message = messageResponse.toMessage() else { return }
            
            let isDuplicate = self.messages.contains { existingMessage in
                existingMessage.id == message.id ||
                (existingMessage.text == message.text &&
                 existingMessage.senderId == message.senderId &&
                 abs(existingMessage.timestamp.timeIntervalSince(message.timestamp)) < 2.0)
            }
            
            if !isDuplicate {
                let myUserId = UserDefaults.standard.integer(forKey: "userId")
                if message.senderId == myUserId {
                    if let tempIndex = self.messages.firstIndex(where: {
                        $0.senderId == myUserId &&
                        $0.text == message.text &&
                        $0.id >= 10000
                    }) {
                        self.messages.remove(at: tempIndex)
                        let tempIndexPath = IndexPath(row: tempIndex, section: 0)
                        self.tableView.deleteRows(at: [tempIndexPath], with: .none)
                    }
                }
                
                let insertIndex = self.messages.firstIndex { $0.timestamp < message.timestamp } ?? 0
                self.messages.insert(message, at: insertIndex)
                let indexPath = IndexPath(row: insertIndex, section: 0)
                self.tableView.insertRows(at: [indexPath], with: .bottom)
            }
        }
        
        if hasLoadedInitialMessages {
            NetworkManager.shared.connectWebSocket(chatRoomId: chatRoomId) { [weak self] result in
                switch result {
                case .success:
                    print("✅ WebSocket 연결 성공")
                case .failure(let error):
                    print("❌ WebSocket 연결 실패: \(error)")
                    if case .authenticationRequired = error {
                        DispatchQueue.main.async {
                            self?.showAlert(title: "인증 오류", message: "다시 로그인해주세요")
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func menuButtonTapped() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "채팅방 나가기", style: .destructive, handler: { [weak self] _ in
            self?.showLeaveChatAlert()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "신고하기", style: .default, handler: { _ in
            // 신고 처리
        }))
        
        actionSheet.addAction(UIAlertAction(title: "차단하기", style: .default, handler: { _ in
            // 차단 처리
        }))
        
        actionSheet.addAction(UIAlertAction(title: "취소", style: .cancel))
        
        present(actionSheet, animated: true)
    }
    
    @objc private func sendButtonTapped() {
        guard let messageText = messageInputField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !messageText.isEmpty else {
            return
        }
        
        sendMessage(messageText)
        messageInputField.text = ""
        updateTextViewHeight()
    }
    
    @objc private func keyboardWillShow(notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }
        
        let keyboardHeight = keyboardFrame.height
        let animationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
        
        messageInputContainerBottomConstraint.constant = -keyboardHeight
        
        UIView.animate(withDuration: animationDuration) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc private func keyboardWillHide(notification: Notification) {
        let animationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
        
        messageInputContainerBottomConstraint.constant = 0
        
        UIView.animate(withDuration: animationDuration) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func showLeaveChatAlert() {
        let alert = UIAlertController(
            title: "채팅방 나가기",
            message: "채팅방을 나가면 대화 내용이 모두 삭제되고 복구할 수 없습니다.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "나가기", style: .destructive, handler: { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }))
        
        present(alert, animated: true)
    }
    
    // MARK: - Message Handling
    private func loadMessages() {
        guard !isLoading && !hasLoadedInitialMessages else {
            print("ℹ️ 메시지 로드 스킵 - 이미 로딩 중이거나 로드 완료됨")
            return
        }
        
        isLoading = true
        
        NetworkManager.shared.getMessages(chatRoomId: chatRoomId) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                self.hasLoadedInitialMessages = true
                
                switch result {
                case .success(let messageResponses):
                    print("✅ 서버에서 메시지 \(messageResponses.count)개 로드")
                    
                    let convertedMessages = messageResponses.compactMap { $0.toMessage() }
                    // 시간순 정렬 (최신 메시지가 위로)
                    self.messages = convertedMessages.sorted(by: { $0.timestamp > $1.timestamp })
                    self.tableView.reloadData()
                    
                    // 메시지 로드 완료 후 WebSocket 설정
                    self.setupWebSocketMessageHandler()
                    self.reconnectWebSocketIfNeeded()
                    
                case .failure(let error):
                    print("❌ 메시지 로드 실패: \(error)")
                    
                    let errorMessage: String
                    switch error {
                    case .authenticationRequired:
                        errorMessage = "로그인이 필요합니다"
                    case .resourceNotFound:
                        errorMessage = "채팅방을 찾을 수 없습니다"
                    default:
                        errorMessage = "메시지를 불러오는 중 오류가 발생했습니다"
                    }
                    
                    // 치명적인 오류가 아닌 경우에만 알림 표시
                    if case .authenticationRequired = error {
                        self.showAlert(title: "오류", message: errorMessage)
                    } else {
                        print("⚠️ 메시지 로드 실패하지만 기존 메시지 유지: \(errorMessage)")
                    }
                    
                    // 에러가 발생해도 WebSocket 설정은 시도
                    self.setupWebSocketMessageHandler()
                    self.reconnectWebSocketIfNeeded()
                }
            }
        }
    }
    
    private func sendMessage(_ text: String) {
        guard NetworkManager.shared.isWebSocketConnected() else {
                showAlert(title: "연결 오류", message: "채팅 서버에 연결되지 않았습니다")
                return
            }
            
            let myUserId = UserDefaults.standard.integer(forKey: "userId")
            let tempId = Int.random(in: 10000...99999)
            
            let tempMessage = Message(
                id: tempId,
                senderId: myUserId,
                text: text,
                timestamp: Date(),
                isRead: true
            )
            
            // 임시 메시지를 UI에 즉시 표시
            messages.insert(tempMessage, at: 0)
            let indexPath = IndexPath(row: 0, section: 0)
            tableView.insertRows(at: [indexPath], with: .bottom)
            
            // WebSocket으로 실제 메시지 전송
            NetworkManager.shared.sendWebSocketMessage(content: text)
        }
    
    private func updateTextViewHeight() {
        let fixedWidth = messageInputField.frame.width
        let newSize = messageInputField.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        
        let minHeight: CGFloat = 36
        let maxHeight: CGFloat = 100
        
        let height = min(max(newSize.height, minHeight), maxHeight)
        messageInputField.constraints.forEach { constraint in
            if constraint.firstAttribute == .height {
                constraint.constant = height
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension ChatDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        let cellIdentifier = message.isFromMe ? "SendMessageCell" : "ReceiveMessageCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? MessageCell else {
            return UITableViewCell()
        }
        
        cell.configure(with: message)
        cell.transform = CGAffineTransform(scaleX: 1, y: -1)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

// MARK: - UITextViewDelegate
extension ChatDetailViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updateTextViewHeight()
    }
}
