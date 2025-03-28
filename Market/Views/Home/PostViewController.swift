//
//  PostViewController.swift
//  Market
//
//  Created by 장동혁 on 3/21/25.
//

import UIKit

class PostViewController: UIViewController {
    
    // MARK: - Properties
    private var selectedImages: [UIImage] = []
    private let maxImageCount = 5
    
    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.backgroundColor = .white
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        return view
    }()
    
    private let imageCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .white
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: "ImageCell")
        collectionView.register(AddImageCell.self, forCellWithReuseIdentifier: "AddImageCell")
        return collectionView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "제목"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let titleTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "제목을 입력해주세요"
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.text = "가격"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let priceTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "가격을 입력해주세요"
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.borderStyle = .roundedRect
        textField.keyboardType = .numberPad
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let placeLabel: UILabel = {
        let label = UILabel()
        label.text = "위치"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let placeTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "위치를 입력해주세요 (선택사항)"
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let contentLabel: UILabel = {
        let label = UILabel()
        label.text = "물건 설명"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let contentTextView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.layer.borderWidth = 0.5
        textView.layer.borderColor = UIColor.lightGray.cgColor
        textView.layer.cornerRadius = 5
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    private let submitButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("작성 완료", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupNavigationBar()
        setupViews()
        setupCollectionView()
        setupTextFieldDelegates()
        setupActions()
    }
    
    // MARK: - Setup Methods
    private func setupNavigationBar() {
        title = "게시물 작성"
        
        // 뒤로가기 버튼 설정
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        backButton.tintColor = .black
        navigationItem.leftBarButtonItem = backButton
    }
    
    private func setupViews() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(imageCollectionView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(titleTextField)
        contentView.addSubview(priceLabel)
        contentView.addSubview(priceTextField)
        contentView.addSubview(placeLabel)
        contentView.addSubview(placeTextField)
        contentView.addSubview(contentLabel)
        contentView.addSubview(contentTextView)
        contentView.addSubview(submitButton)
        
        // ScrollView Constraints
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Image Collection View
            imageCollectionView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            imageCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageCollectionView.heightAnchor.constraint(equalToConstant: 120),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: imageCollectionView.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            titleTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            titleTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Price
            priceLabel.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 16),
            priceLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            priceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            priceTextField.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 8),
            priceTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            priceTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            priceTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Place
            placeLabel.topAnchor.constraint(equalTo: priceTextField.bottomAnchor, constant: 16),
            placeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            placeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            placeTextField.topAnchor.constraint(equalTo: placeLabel.bottomAnchor, constant: 8),
            placeTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            placeTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            placeTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Content
            contentLabel.topAnchor.constraint(equalTo: placeTextField.bottomAnchor, constant: 16),
            contentLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contentLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            contentTextView.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 8),
            contentTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contentTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            contentTextView.heightAnchor.constraint(equalToConstant: 150),
            
            // Submit Button
            submitButton.topAnchor.constraint(equalTo: contentTextView.bottomAnchor, constant: 32),
            submitButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            submitButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            submitButton.heightAnchor.constraint(equalToConstant: 50),
            submitButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])
    }
    
    private func setupCollectionView() {
        imageCollectionView.delegate = self
        imageCollectionView.dataSource = self
    }
    
    private func setupTextFieldDelegates() {
        titleTextField.delegate = self
        priceTextField.delegate = self
        placeTextField.delegate = self
        
        // 가격 숫자 포맷팅
        priceTextField.addTarget(self, action: #selector(priceTextFieldDidChange), for: .editingChanged)
    }
    
    private func setupActions() {
        submitButton.addTarget(self, action: #selector(submitButtonTapped), for: .touchUpInside)
        
        // 키보드 dismiss를 위한 탭 제스처 추가
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Actions
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func priceTextFieldDidChange(_ textField: UITextField) {
        // 숫자만 추출
        if let text = textField.text?.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression) {
            let number = Int(text) ?? 0
            
            // 숫자 포맷팅 (천 단위 구분)
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            
            if let formattedNumber = formatter.string(from: NSNumber(value: number)) {
                // "₩" 접두사와, 기존 입력과 커서 위치 고려하여 설정
                let priceText = "₩\(formattedNumber)"
                
                // 숫자가 0인 경우 접두사만 표시
                if number == 0 && !text.isEmpty {
                    textField.text = "₩"
                } else {
                    textField.text = priceText
                }
            }
        } else {
            textField.text = "₩"
        }
    }
    
    @objc private func submitButtonTapped() {
        // 이미지 최적화 및 제출 처리
        processImagesAndSubmit()
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Helper Methods
    private func validateForm() -> Bool {
        // 제목 검사
        guard let title = titleTextField.text, !title.isEmpty else {
            showAlert(message: "제목을 입력해주세요.")
            return false
        }
        
        // 가격 검사
        guard let priceText = priceTextField.text?.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression),
              let price = Int(priceText), price > 0 else {
            showAlert(message: "유효한 가격을 입력해주세요.")
            return false
        }
        
        // 내용 검사
        guard let content = contentTextView.text, !content.isEmpty else {
            showAlert(message: "물건 설명을 입력해주세요.")
            return false
        }
        
        return true
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
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
        let height = message.height(withConstrainedWidth: maxWidth, font: toastLabel.font) + 20
        
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
    
    private func showImagePicker() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = false
        present(imagePicker, animated: true)
    }
    
    private func showLoadingIndicator() {
        if loadingIndicator.superview == nil {
            view.addSubview(loadingIndicator)
            NSLayoutConstraint.activate([
                loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
        }
        loadingIndicator.startAnimating()
        view.isUserInteractionEnabled = false
    }
    
    private func hideLoadingIndicator() {
        loadingIndicator.stopAnimating()
        view.isUserInteractionEnabled = true
    }
    
    // MARK: - 이미지 처리 및 업로드 메서드
    func processImagesAndSubmit() {
        // 폼 유효성 검사
        guard validateForm() else { return }
        
        // 게시물 정보 추출
        guard let title = titleTextField.text, !title.isEmpty,
              let priceText = priceTextField.text?.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression),
              let price = Int(priceText), price > 0,
              let content = contentTextView.text, !content.isEmpty else {
            showAlert(message: "필수 정보를 모두 입력해주세요.")
            return
        }
        
        let place = placeTextField.text
        
        // 로딩 인디케이터 표시
        showLoadingIndicator()
        
        // 이미지 처리는 백그라운드에서 진행 (UI 차단 방지)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // 이미지 최적화 처리
            let processedImages = self.optimizeImages(self.selectedImages)
            
            // UI 업데이트는 메인 스레드에서
            DispatchQueue.main.async {
                // 게시물 업로드 시작
                self.uploadPost(title: title, content: content, price: price, place: place, images: processedImages)
            }
        }
    }
    
    // 이미지 최적화 함수
    private func optimizeImages(_ images: [UIImage]) -> [Data] {
        var optimizedImageDataArray: [Data] = []
        
        for (index, originalImage) in images.enumerated() {
            // 이미지 크기 확인 및 로깅
            let originalSizeKB = originalImage.jpegData(compressionQuality: 1.0)?.count ?? 0
            print("🖼️ 원본 이미지 #\(index+1) 크기: \(Double(originalSizeKB) / 1024.0)KB")
            
            // 1. 이미지 크기 조정
            let resizedImage = resizeImageIfNeeded(originalImage, maxDimension: 1600)
            
            // 2. 이미지 압축
            let maxSizeKB: Double = 800
            let targetCompression: CGFloat = 0.9
            
            // 압축 시도
            if var imageData = compressImage(resizedImage, targetSizeKB: maxSizeKB, initialCompression: targetCompression) {
                // 성공적으로 압축된 경우
                let finalSizeKB = Double(imageData.count) / 1024.0
                print("✅ 이미지 #\(index+1) 최적화 완료: \(String(format: "%.1f", finalSizeKB))KB")
                optimizedImageDataArray.append(imageData)
            } else {
                // 압축 실패 시 최소 압축률로 시도
                print("⚠️ 이미지 압축 최적화 실패, 마지막 시도...")
                if let lastResortData = resizedImage.jpegData(compressionQuality: 0.7) {
                    let sizeLimitMB = 1.0  // 1MB 제한
                    if Double(lastResortData.count) / (1024.0 * 1024.0) <= sizeLimitMB {
                        // 1MB 이하면 사용
                        optimizedImageDataArray.append(lastResortData)
                        print("⚠️ 이미지 #\(index+1) 비상 압축 적용: \(Double(lastResortData.count) / 1024.0)KB")
                    } else {
                        print("❌ 이미지 #\(index+1)이 너무 큽니다. 건너뜁니다.")
                        // 알림 표시 (메인 스레드에서)
                        DispatchQueue.main.async {
                            let message = "이미지 #\(index+1)이 너무 커서 처리할 수 없습니다."
                            self.showToast(message: message)
                        }
                    }
                }
            }
        }
        
        return optimizedImageDataArray
    }
    
    // 이미지 리사이징 함수 (개선)
    private func resizeImageIfNeeded(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let originalWidth = image.size.width
        let originalHeight = image.size.height
        
        // 이미지가 이미 적정 크기이면 그대로 반환
        if max(originalWidth, originalHeight) <= maxDimension {
            return image
        }
        
        // 비율 계산
        let scale = maxDimension / max(originalWidth, originalHeight)
        let newWidth = originalWidth * scale
        let newHeight = originalHeight * scale
        let newSize = CGSize(width: newWidth, height: newHeight)
        
        // 리사이징 (품질 유지를 위해 옵션 조정)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        
        print("   이미지 리사이징: \(Int(originalWidth))x\(Int(originalHeight)) → \(Int(newWidth))x\(Int(newHeight))")
        
        return resizedImage
    }
    
    // 이미지 압축 함수
    private func compressImage(_ image: UIImage, targetSizeKB: Double, initialCompression: CGFloat) -> Data? {
        let maxBytes = Int(targetSizeKB * 1024)
        let maxAttempts = 8  // 최대 시도 횟수
        
        // 압축률 범위
        var minCompression: CGFloat = 0.1
        var maxCompression: CGFloat = 1.0
        var compression = initialCompression
        
        var bestData: Data? = nil
        var bestCompression: CGFloat = 0.1
        
        for attempt in 1...maxAttempts {
            if let data = image.jpegData(compressionQuality: compression) {
                let sizeKB = Double(data.count) / 1024.0
                print("   압축 시도 #\(attempt): 압축률 \(Int(compression * 100))%, 크기 \(String(format: "%.1f", sizeKB))KB")
                
                if data.count <= maxBytes {
                    // 목표 크기보다 작아진 경우, 가능한 높은 품질 유지
                    bestData = data
                    bestCompression = compression
                    minCompression = compression
                    
                    // 이미 충분히 작으면 더 시도할 필요 없음
                    if data.count >= Int(Double(maxBytes) * 0.95) {
                        print("   적정 크기 도달!")
                        return data
                    }
                } else {
                    // 여전히 큰 경우
                    maxCompression = compression
                }
                
                // 다음 시도를 위한 중간값 계산
                compression = (minCompression + maxCompression) / 2
            } else {
                // 압축 실패, 더 낮은 압축률 시도
                maxCompression = compression
                compression = (minCompression + maxCompression) / 2
            }
        }
        
        // 최선의 결과 반환
        if let data = bestData {
            print("   최종 압축률: \(Int(bestCompression * 100))%, 크기: \(Double(data.count) / 1024.0)KB")
            return data
        }
        
        // 모든 시도 실패
        return nil
    }
    
    // 게시물 업로드 함수 (개선)
    private func uploadPost(title: String, content: String, price: Int, place: String?, images: [Data]) {
        // 업로드 시작 로그
        print("🚀 게시물 업로드 시작")
        print("   - 제목: \(title)")
        print("   - 내용: \(content.prefix(30))...")
        print("   - 가격: \(price)")
        print("   - 위치: \(place ?? "없음")")
        print("   - 이미지: \(images.count)개")
        
        // 각 이미지 크기 로깅
        for (i, imageData) in images.enumerated() {
            let sizeKB = Double(imageData.count) / 1024.0
            print("   - 이미지 #\(i+1) 크기: \(String(format: "%.1f", sizeKB))KB")
        }
        
        // 요청 시작
        NetworkManager.shared.createPost(
            title: title,
            content: content,
            price: price,
            place: place,
            images: images.isEmpty ? nil : images
        ) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.hideLoadingIndicator()
                
                switch result {
                case .success(let post):
                    print("✅ 게시물 업로드 성공 (ID: \(post.id))")
                    // Toast 메시지로 성공 알림
                    self.showToast(message: "게시물이 등록되었습니다 (ID: \(post.id))")
                    
                    // 잠시 후 홈 화면으로 돌아가기 (사용자가 토스트 메시지를 볼 수 있도록)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                    
                case .failure(let error):
                    print("❌ 게시물 업로드 실패: \(error.localizedDescription)")
                    
                    // 오류 유형에 따른 처리
                    if let networkError = error as? NetworkManager.NetworkError {
                        switch networkError {
                        case .serverError(let code):
                            if code == 500 {
                                // 서버 내부 오류 - 더 자세한 오류 메시지
                                let errorMessage = """
                                서버 오류가 발생했습니다. (500)
                                
                                다음 사항을 확인해보세요:
                                • 입력한 정보가 올바른지 확인
                                • 이미지 크기가 너무 크지 않은지 확인
                                • 잠시 후 다시 시도하세요
                                """
                                self.showAlert(message: errorMessage)
                            } else {
                                self.showAlert(message: "서버 오류가 발생했습니다 (코드: \(code))")
                            }
                        case .authenticationRequired:
                            self.showLoginRequiredAlert()
                        case .invalidCredentials:
                            self.showAlert(message: "인증에 실패했습니다. 다시 로그인해주세요.")
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                self.showLoginRequiredAlert()
                            }
                        default:
                            self.showAlert(message: networkError.errorDescription ?? "알 수 없는 오류가 발생했습니다.")
                        }
                    } else {
                        // 그 외 일반 오류
                        self.showAlert(message: "게시물 업로드 중 오류가 발생했습니다: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // 로그인 필요 알림
    func showLoginRequiredAlert() {
        let alert = UIAlertController(
            title: "로그인 필요",
            message: "로그인 세션이 만료되었습니다. 다시 로그인해주세요.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "로그인", style: .default) { [weak self] _ in
            // 토큰 삭제
            UserDefaults.standard.removeObject(forKey: "userToken")
            
            // 홈 화면으로 이동
            self?.navigationController?.popToRootViewController(animated: true)
        })
            present(alert, animated: true)
        }
    }

    // MARK: - String Extension
    extension String {
        func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
            let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
            let boundingBox = self.boundingRect(
                with: constraintRect,
                options: .usesLineFragmentOrigin,
                attributes: [NSAttributedString.Key.font: font],
                context: nil
            )
            return boundingBox.height
        }
    }

    // MARK: - UITextFieldDelegate
    extension PostViewController: UITextFieldDelegate {
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            // 다음 텍스트 필드로 포커스 이동
            if textField == titleTextField {
                priceTextField.becomeFirstResponder()
            } else if textField == priceTextField {
                placeTextField.becomeFirstResponder()
            } else if textField == placeTextField {
                contentTextView.becomeFirstResponder()
            }
            
            return true
        }
    }

    // MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate
    extension PostViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let selectedImage = info[.originalImage] as? UIImage {
                // 최대 이미지 개수 확인
                if selectedImages.count < maxImageCount {
                    selectedImages.append(selectedImage)
                    imageCollectionView.reloadData()
                } else {
                    showAlert(message: "이미지는 최대 \(maxImageCount)개까지 선택할 수 있습니다.")
                }
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }

    // MARK: - UICollectionViewDelegate, UICollectionViewDataSource
    extension PostViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
        func numberOfSections(in collectionView: UICollectionView) -> Int {
            return 1
        }
        
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            // 선택한 이미지 + 추가 버튼 셀
            return selectedImages.count + 1
        }
        
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            if indexPath.item < selectedImages.count {
                // 이미지 셀
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCell
                cell.configure(with: selectedImages[indexPath.item])
                
                // 이미지 삭제 액션 설정
                cell.deleteAction = { [weak self] in
                    guard let self = self else { return }
                    self.selectedImages.remove(at: indexPath.item)
                    self.imageCollectionView.reloadData()
                }
                
                return cell
            } else {
                // 이미지 추가 버튼 셀
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddImageCell", for: indexPath) as! AddImageCell
                cell.isHidden = selectedImages.count >= maxImageCount
                return cell
            }
        }
        
        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            if indexPath.item == selectedImages.count && selectedImages.count < maxImageCount {
                // 이미지 추가 버튼 탭
                showImagePicker()
            }
        }
        
        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            return CGSize(width: 100, height: 100)
        }
    }

    // MARK: - Image Collection View Cells
    class ImageCell: UICollectionViewCell {
        
        private let imageView: UIImageView = {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = 8
            imageView.translatesAutoresizingMaskIntoConstraints = false
            return imageView
        }()
        
        private let deleteButton: UIButton = {
            let button = UIButton(type: .system)
            button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
            button.tintColor = .systemRed
            button.backgroundColor = .white
            button.layer.cornerRadius = 10
            button.translatesAutoresizingMaskIntoConstraints = false
            return button
        }()
        
        var deleteAction: (() -> Void)?
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setupViews()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupViews() {
            contentView.layer.cornerRadius = 8
            contentView.layer.borderWidth = 0.5
            contentView.layer.borderColor = UIColor.lightGray.cgColor
            contentView.clipsToBounds = true
            
            contentView.addSubview(imageView)
            contentView.addSubview(deleteButton)
            
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                
                deleteButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
                deleteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5),
                deleteButton.widthAnchor.constraint(equalToConstant: 20),
                deleteButton.heightAnchor.constraint(equalToConstant: 20)
            ])
            
            deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        }
        
        func configure(with image: UIImage) {
            imageView.image = image
        }
        
        @objc private func deleteButtonTapped() {
            deleteAction?()
        }
    }

    class AddImageCell: UICollectionViewCell {
        
        private let plusButton: UIButton = {
            let button = UIButton(type: .system)
            button.setImage(UIImage(systemName: "plus"), for: .normal)
            button.tintColor = .darkGray
            button.translatesAutoresizingMaskIntoConstraints = false
            return button
        }()
        
        private let label: UILabel = {
            let label = UILabel()
            label.text = "사진 추가"
            label.font = UIFont.systemFont(ofSize: 12)
            label.textColor = .darkGray
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setupViews()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupViews() {
            contentView.layer.cornerRadius = 8
            contentView.layer.borderWidth = 0.5
            contentView.layer.borderColor = UIColor.lightGray.cgColor
            contentView.backgroundColor = UIColor.systemGray6
            
            contentView.addSubview(plusButton)
            contentView.addSubview(label)
            
            NSLayoutConstraint.activate([
                plusButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                plusButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -10),
                plusButton.widthAnchor.constraint(equalToConstant: 40),
                plusButton.heightAnchor.constraint(equalToConstant: 40),
                
                label.topAnchor.constraint(equalTo: plusButton.bottomAnchor, constant: 5),
                label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5),
                label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5)
            ])
        }
    }
