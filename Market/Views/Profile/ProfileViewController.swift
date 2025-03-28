//
//  ProfileViewController.swift
//  Market
//
//  Created by 장동혁 on 1/30/25.
//

import UIKit

class ProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // 프로필 이미지
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person.circle.fill")
        imageView.tintColor = .systemGray4
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 50
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true // Touchable
        return imageView
    }()
    
    // 프로필 타이틀 Label
    private let profileLabel: UILabel = {
        let label = UILabel()
        label.text = "내 정보"
        label.font = .systemFont(ofSize: 35, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    // Name Label
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.text = "사용자 이름"  // 기본값 설정
        label.font = .systemFont(ofSize: 24, weight: .bold)
        return label
    }()
    
    // E-mail Label
    private let emailLabel: UILabel = {
        let label = UILabel()
        label.text = "이메일"  // 기본값 설정
        label.font = .systemFont(ofSize: 16)
        label.textColor = .gray
        label.textAlignment = .center
        return label
    }()
    
    // 프로필 수정 버튼
    private let editProfileButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("프로필 수정", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        return button
    }()
    
    // 위시리스트 버튼
    private let wishlistButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("내 위시리스트", for: .normal)
        button.backgroundColor = .systemIndigo
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        return button
    }()
    
    // 회원 탈퇴 버튼
    private let deleteAccountButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("회원 탈퇴", for: .normal)
        button.backgroundColor = .systemRed
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        return button
    }()
    
    // 로그아웃 버튼
    private let logoutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("로그아웃", for: .normal)
        button.backgroundColor = .systemGray4
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        return button
    }()
    
    // 하단 탭바
    private let customTabBar = CustomTabBar()
    
    private var token: String?
    private var userId: Int?
    private var isLoadingProfile = false
    
    // 프로필 로드 여부 추적 - 앱 전역 상태로 변경
    // 정적 프로퍼티로 전환하여 앱 라이프사이클 동안 유지
    private static var hasLoadedProfile = false
    
    // 마지막 프로필 로드 시간 추적
    private static var lastProfileLoadTime: Date?
    
    // 프로필 데이터
    private static var cachedUserData: UserDTO?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupNavigationBar()
        setupViews()
        setupTabBar()
        setupImageTapGesture()
        
        // 최초 로드 또는 캐시된 데이터 표시
        if let cachedData = ProfileViewController.cachedUserData {
            // 캐시된 데이터가 있으면 바로 표시
            print("✅ 캐시된 프로필 데이터 사용")
            updateProfileUI(with: cachedData)
        } else {
            // 캐시된 데이터가 없으면 로드
            loadUserProfileIfNeeded()
        }
    }
    
    // 프로필 이미지 변경
    private func setupImageTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(profileImageTapped))
        profileImageView.addGestureRecognizer(tapGesture)
    }
    
    @objc private func profileImageTapped() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editedImage = info[.editedImage] as? UIImage {
            profileImageView.image = editedImage
            profileImageView.tintColor = .clear
        } else if let originalImage = info[.originalImage] as? UIImage {
            profileImageView.image = originalImage
            profileImageView.tintColor = .clear
        }
        dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
    
    private func setupNavigationBar() {
        navigationItem.hidesBackButton = true
    }
    
    private func setupViews() {
        // Profile Label
        view.addSubview(profileLabel)
        profileLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Profile Image
        view.addSubview(profileImageView)
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Name Label
        view.addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Email Label
        view.addSubview(emailLabel)
        emailLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Buttons
        [editProfileButton, wishlistButton, deleteAccountButton, logoutButton].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            // Profile Label
            profileLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            profileLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Profile Image
            profileImageView.topAnchor.constraint(equalTo: profileLabel.bottomAnchor, constant: 40),
            profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 100),
            profileImageView.heightAnchor.constraint(equalToConstant: 100),
            
            // Name Label
            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 20),
            nameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Email Label
            emailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            emailLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Edit Profile Button
            editProfileButton.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 30),
            editProfileButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            editProfileButton.widthAnchor.constraint(equalToConstant: 200),
            editProfileButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Wishlist Button
            wishlistButton.topAnchor.constraint(equalTo: editProfileButton.bottomAnchor, constant: 16),
            wishlistButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            wishlistButton.widthAnchor.constraint(equalToConstant: 200),
            wishlistButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Delete Account Button
            deleteAccountButton.topAnchor.constraint(equalTo: wishlistButton.bottomAnchor, constant: 16),
            deleteAccountButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            deleteAccountButton.widthAnchor.constraint(equalToConstant: 200),
            deleteAccountButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Logout Button
            logoutButton.topAnchor.constraint(equalTo: deleteAccountButton.bottomAnchor, constant: 16),
            logoutButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoutButton.widthAnchor.constraint(equalToConstant: 200),
            logoutButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // 버튼 액션 추가
        editProfileButton.addTarget(self, action: #selector(editProfileTapped), for: .touchUpInside)
        wishlistButton.addTarget(self, action: #selector(wishlistTapped), for: .touchUpInside)
        deleteAccountButton.addTarget(self, action: #selector(deleteAccountTapped), for: .touchUpInside)
        logoutButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
    }
    
    // 탭바 설정
    private func setupTabBar() {
        view.addSubview(customTabBar)
        customTabBar.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            customTabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customTabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customTabBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            customTabBar.heightAnchor.constraint(equalToConstant: 90)
        ])
        
        // 프로필 화면에서는 프로필 버튼이 선택된 상태로 표시
        customTabBar.updateButtonColors(customTabBar.profileButton)
        
        customTabBar.didTapButton = { [weak self] button in
            switch button {
            case self?.customTabBar.homeButton:
                let homeVC = HomeViewController()
                self?.navigationController?.pushViewController(homeVC, animated: false)
            case self?.customTabBar.chatButton:
                let chatVC = ChatViewController()
                self?.navigationController?.pushViewController(chatVC, animated: false)
            case self?.customTabBar.profileButton:
                print("Already in Profile")
            default:
                break
            }
        }
    }
    
    // 필요한 경우에만 프로필 로드
    private func loadUserProfileIfNeeded() {
        // 프로필이 이미 로드되었고, 마지막 로드 후 30분이 경과하지 않았으면 스킵
        if ProfileViewController.hasLoadedProfile,
           let lastLoad = ProfileViewController.lastProfileLoadTime,
           Date().timeIntervalSince(lastLoad) < 1800 { // 30분(1800초)
            print("✅ 프로필 이미 로드됨, 로드 시간이 30분 이내임")
            
            // 캐시된 데이터가 있으면 사용
            if let cachedData = ProfileViewController.cachedUserData {
                updateProfileUI(with: cachedData)
            }
            return
        }
        
        // 프로필 변경 플래그 확인
        let needsRefresh = UserDefaults.standard.bool(forKey: "profileNeedsRefresh")
        
        if needsRefresh || !ProfileViewController.hasLoadedProfile {
            // 새로고침 필요하거나 최초 로드인 경우
            UserDefaults.standard.set(false, forKey: "profileNeedsRefresh")
            // 프로필 다시 로드
            loadUserProfile()
        }
    }
    
    // 프로필 관리
    private func loadUserProfile() {
        // 이미 로딩 중이면 중복 호출 방지
        if isLoadingProfile {
            print("⚠️ 이미 프로필 로딩 중입니다.")
            return
        }
        
        isLoadingProfile = true
        print("🔄 프로필 로딩 시작")
        
        guard let token = UserDefaults.standard.string(forKey: "userToken") else {
            print("❌ 토큰이 없습니다. 로그인 화면으로 이동합니다.")
            isLoadingProfile = false
            navigateToLogin()
            return
        }
        self.token = token
        print("✅ 토큰 확인: \(String(describing: token.prefix(15)))...")
        
        // userId 확인
        guard let userId = UserDefaults.standard.object(forKey: "userId") as? Int else {
            print("❌ userId가 없습니다.")
            isLoadingProfile = false
            showAlert(message: "사용자 정보를 찾을 수 없습니다.")
            return
        }
        self.userId = userId
        print("✅ userId 확인: \(userId)")
        
        // 로딩 표시
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = view.center
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
        
        print("🔄 서버에 사용자 정보 요청 중 (userId: \(userId))")
        
        // 서버에서 사용자 정보 조회
        NetworkManager.shared.getUserProfile(userId: userId) { [weak self] result in
            guard let self = self else {
                print("❌ self가 해제됨")
                return
            }
            
            DispatchQueue.main.async {
                activityIndicator.removeFromSuperview()
                self.isLoadingProfile = false
                
                switch result {
                case .success(let userDTO):
                    print("✅ 사용자 정보 로드 성공:")
                    print("   - 닉네임: \(userDTO.nickname)")
                    print("   - 이메일: \(userDTO.email)")
                    
                    // 캐시에 저장
                    ProfileViewController.cachedUserData = userDTO
                    
                    // 로드 시간 기록
                    ProfileViewController.lastProfileLoadTime = Date()
                    
                    // UI 업데이트 전 현재 값 로깅
                    print("🔄 UI 업데이트 전:")
                    print("   - 현재 nameLabel: \(self.nameLabel.text ?? "nil")")
                    print("   - 현재 emailLabel: \(self.emailLabel.text ?? "nil")")
                    
                    self.updateProfileUI(with: userDTO)
                    
                    // 프로필 로드 완료 플래그 설정
                    ProfileViewController.hasLoadedProfile = true
                    
                    // UI 업데이트 검증
                    print("✅ UI 업데이트 후:")
                    print("   - 업데이트된 nameLabel: \(self.nameLabel.text ?? "nil")")
                    print("   - 업데이트된 emailLabel: \(self.emailLabel.text ?? "nil")")
                    
                case .failure(let error):
                    print("❌ 사용자 정보 로드 실패: \(error.localizedDescription)")
                    
                    if let networkError = error as? NetworkManager.NetworkError {
                        if case .invalidCredentials = networkError {
                            self.showAlert(message: "인증에 실패했습니다. 다시 로그인해주세요.")
                            self.navigateToLogin()
                        } else if case .serverError(let code) = networkError {
                            self.showAlert(message: "서버 오류가 발생했습니다. (코드: \(code))")
                        } else {
                            self.showAlert(message: networkError.localizedDescription)
                        }
                    } else {
                        self.showAlert(message: "사용자 정보를 불러오는데 실패했습니다: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // UI Update
    private func updateProfileUI(with userDTO: UserDTO) {
        print("🔄 updateProfileUI 호출됨")
        
        // 강제로 메인 스레드에서 실행 보장
        if Thread.isMainThread {
            print("✅ 현재 메인 스레드에서 실행 중")
            nameLabel.text = userDTO.nickname
            emailLabel.text = userDTO.email
        } else {
            print("⚠️ 메인 스레드가 아님, dispatch 사용")
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.nameLabel.text = userDTO.nickname
                self.emailLabel.text = userDTO.email
                print("✅ 메인 스레드에서 UI 업데이트 완료")
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 프로필 수정 후에만 새로고침
        if let needsRefresh = UserDefaults.standard.object(forKey: "profileNeedsRefresh") as? Bool, needsRefresh {
            print("♻️ 프로필 변경 감지됨, 새로고침 필요")
            // 새로고침 플래그 초기화
            UserDefaults.standard.set(false, forKey: "profileNeedsRefresh")
            // 프로필 다시 로드
            loadUserProfile()
        } else if !ProfileViewController.hasLoadedProfile {
            // 최초 로드가 아직 안된 경우에만 로드
            print("♻️ 최초 로드가 필요함")
            loadUserProfile()
        } else {
            print("✅ 프로필 이미 로드됨, 새로고침 불필요")
            
            // 이미 캐시된 데이터가 있으면 UI 업데이트
            if let cachedData = ProfileViewController.cachedUserData {
                updateProfileUI(with: cachedData)
            }
        }
    }
    
    @objc private func editProfileTapped() {
        let editVC = EditProfileViewController()
        editVC.completion = { [weak self] in
            // 프로필 수정 완료 시 새로고침 필요 플래그 설정
            UserDefaults.standard.set(true, forKey: "profileNeedsRefresh")
            
            // 캐시 무효화
            ProfileViewController.cachedUserData = nil
            
            // 프로필 재로드
            self?.loadUserProfile()
        }
        present(editVC, animated: true)
    }
    
    @objc private func wishlistTapped() {
        // 위시리스트 화면으로 이동
        let wishlistVC = WishlistViewController()
        navigationController?.pushViewController(wishlistVC, animated: true)
    }
    
    @objc private func deleteAccountTapped() {
        let alert = UIAlertController(
            title: "회원 탈퇴",
            message: "정말로 탈퇴하시겠습니까?\n 이 작업은 되돌릴 수 없습니다.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "탈퇴", style: .destructive) { [weak self] _ in
            self?.deleteAccount()
        })
        
        present(alert, animated: true)
    }
    
    private func deleteAccount() {
        guard let token = self.token else {
            print("❌ 토큰이 없어 회원 탈퇴를 진행할 수 없습니다.")
            return
        }
        
        // Loading
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = view.center
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
        
        print("🔄 회원 탈퇴 요청 중...")
        
        NetworkManager.shared.deleteAccount(token: token) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                activityIndicator.removeFromSuperview()
                
                switch result {
                case .success:
                    print("✅ 회원 탈퇴 성공")
                    UserDefaults.standard.removeObject(forKey: "userToken")
                    UserDefaults.standard.removeObject(forKey: "userId")
                    UserDefaults.standard.removeObject(forKey: "profileNeedsRefresh")
                    
                    // 정적 프로퍼티 초기화
                    ProfileViewController.hasLoadedProfile = false
                    ProfileViewController.lastProfileLoadTime = nil
                    ProfileViewController.cachedUserData = nil
                    
                    self.navigateToLogin()
                case .failure(let error):
                    print("❌ 회원 탈퇴 실패: \(error.localizedDescription)")
                    self.showAlert(message: "회원 탈퇴 실패: \(error.localizedDescription)")
                }
            }
        }
    }
    
    @objc private func logoutTapped() {
        print("🔄 로그아웃 진행")
        UserDefaults.standard.removeObject(forKey: "userToken")
        UserDefaults.standard.removeObject(forKey: "userId")
        UserDefaults.standard.removeObject(forKey: "profileNeedsRefresh")
        
        // 정적 프로퍼티 초기화
        ProfileViewController.hasLoadedProfile = false
        ProfileViewController.lastProfileLoadTime = nil
        ProfileViewController.cachedUserData = nil
        
        navigateToLogin()
    }
    
    private func navigateToLogin() {
        let loginVC = LoginViewController()
        navigationController?.setViewControllers([loginVC], animated: true)
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(
            title: "알림",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - 임시 WishlistViewController (실제 구현은 별도로 필요)
class WishlistViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "내 위시리스트"
        
        // 이곳에 위시리스트 구현 코드를 추가하세요
    }
}
