//
//  ReviewViewController.swift
//  Market
//
//  Created by 장동혁 on 5/15/25.
//

import UIKit

class ReviewViewController: UIViewController {
    
    // 리뷰 대상 사용자 정보
    var targetUserId: Int?
    var targetUserName: String?
    var postId: Int?
    
    // UI 컴포넌트
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "리뷰 작성"
        label.font = .systemFont(ofSize: 30, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private let targetUserLabel: UILabel = {
        let label = UILabel()
        label.text = "판매자: "
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.textAlignment = .left
        return label
    }()
    
    private let ratingLabel: UILabel = {
        let label = UILabel()
        label.text = "별점"
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textAlignment = .left
        return label
    }()
    
    // 별점 컨테이너 뷰 (별점 버튼들을 담을 뷰)
    private let ratingContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    // 별점 버튼 (5개의 별)
    private var starButtons: [UIButton] = []
    private var currentRating: Int = 0
    
    // 리뷰 텍스트 뷰
    private let reviewTextViewLabel: UILabel = {
        let label = UILabel()
        label.text = "리뷰 내용"
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textAlignment = .left
        return label
    }()
    
    private let reviewTextView: UITextView = {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 16)
        textView.layer.borderColor = UIColor.lightGray.cgColor
        textView.layer.borderWidth = 1.0
        textView.layer.cornerRadius = 8
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        return textView
    }()
    
    // 제출 버튼
    private let submitButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("리뷰 제출", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        setupNavigationBar()
        createStarButtons()
        setupActions()
        
        // 더미 데이터 설정 (나중에 실제 데이터로 교체)
        setDummyData()
    }
    
    private func setupNavigationBar() {
        title = "리뷰 작성"
        navigationController?.navigationBar.prefersLargeTitles = false
        
        // 뒤로가기 버튼
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
    }
    
    private func setupUI() {
        // Add subviews
        [titleLabel, targetUserLabel, ratingLabel, ratingContainerView, reviewTextViewLabel, reviewTextView, submitButton].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Title Label
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Target User Label
            targetUserLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            targetUserLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            targetUserLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Rating Label
            ratingLabel.topAnchor.constraint(equalTo: targetUserLabel.bottomAnchor, constant: 25),
            ratingLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            ratingLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Rating Container View
            ratingContainerView.topAnchor.constraint(equalTo: ratingLabel.bottomAnchor, constant: 10),
            ratingContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            ratingContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            ratingContainerView.heightAnchor.constraint(equalToConstant: 40),
            
            // Review Text View Label
            reviewTextViewLabel.topAnchor.constraint(equalTo: ratingContainerView.bottomAnchor, constant: 25),
            reviewTextViewLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            reviewTextViewLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Review Text View
            reviewTextView.topAnchor.constraint(equalTo: reviewTextViewLabel.bottomAnchor, constant: 10),
            reviewTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            reviewTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            reviewTextView.heightAnchor.constraint(equalToConstant: 180),
            
            // Submit Button
            submitButton.topAnchor.constraint(equalTo: reviewTextView.bottomAnchor, constant: 30),
            submitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            submitButton.widthAnchor.constraint(equalToConstant: 200),
            submitButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func createStarButtons() {
        // 별 5개 생성
        for i in 0..<5 {
            let button = UIButton(type: .system)
            button.setImage(UIImage(systemName: "star"), for: .normal)
            button.tintColor = .systemYellow
            button.tag = i + 1 // 1부터 5까지의 태그 부여
            button.addTarget(self, action: #selector(starButtonTapped(_:)), for: .touchUpInside)
            
            starButtons.append(button)
            ratingContainerView.addSubview(button)
            button.translatesAutoresizingMaskIntoConstraints = false
        }
        
        // 별 버튼 레이아웃
        let buttonWidth: CGFloat = 40
        let spacing: CGFloat = 10
        
        for (index, button) in starButtons.enumerated() {
            NSLayoutConstraint.activate([
                button.topAnchor.constraint(equalTo: ratingContainerView.topAnchor),
                button.leadingAnchor.constraint(equalTo: ratingContainerView.leadingAnchor, constant: CGFloat(index) * (buttonWidth + spacing)),
                button.widthAnchor.constraint(equalToConstant: buttonWidth),
                button.heightAnchor.constraint(equalToConstant: buttonWidth)
            ])
        }
    }
    
    private func setupActions() {
        submitButton.addTarget(self, action: #selector(submitButtonTapped), for: .touchUpInside)
        
        // 키보드 설정
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    // 더미 데이터 설정 (실제 사용 시 제거)
    private func setDummyData() {
        targetUserId = 123
        targetUserName = ""
        postId = 456
        
        targetUserLabel.text = "판매자 \(targetUserName ?? "알 수 없음")"
    }
    
    // MARK: - Actions
    
    @objc private func starButtonTapped(_ sender: UIButton) {
        let rating = sender.tag
        
        // 별점 업데이트
        updateRating(rating)
    }
    
    private func updateRating(_ rating: Int) {
        currentRating = rating
        
        // 모든 별 초기화
        for (index, button) in starButtons.enumerated() {
            let imageName = index < rating ? "star.fill" : "star"
            button.setImage(UIImage(systemName: imageName), for: .normal)
        }
    }
    
    @objc private func submitButtonTapped() {
        // 입력 검증
        guard currentRating > 0 else {
            showAlert(message: "별점을 선택해주세요.")
            return
        }
        
        guard let reviewText = reviewTextView.text, !reviewText.isEmpty else {
            showAlert(message: "리뷰 내용을 입력해주세요.")
            return
        }
        
        guard let targetUserId = targetUserId, let postId = postId else {
            showAlert(message: "리뷰 대상 정보가 올바르지 않습니다.")
            return
        }
        
        // 로딩 표시
        showLoadingIndicator()
        
        // API 호출
        submitReview(postId: postId, revieweeId: targetUserId, rating: currentRating, comment: reviewText)
    }
    
    private func submitReview(postId: Int, revieweeId: Int, rating: Int, comment: String) {
        // 토큰 가져오기
        guard let token = UserDefaults.standard.string(forKey: "userToken") else {
            hideLoadingIndicator()
            showAlert(message: "로그인이 필요합니다.")
            return
        }
        
        // ReviewRequestDTO 생성
        let reviewDTO = ReviewRequestDTO(rating: rating, comment: comment)
        
        // API 호출
        NetworkManager.shared.createReview(postId: postId, revieweeId: revieweeId, requestDTO: reviewDTO, token: token) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.hideLoadingIndicator()
                
                switch result {
                case .success:
                    self.showAlert(message: "리뷰가 성공적으로 등록되었습니다.") { _ in
                        self.navigationController?.popViewController(animated: true)
                    }
                case .failure(let error):
                    self.showAlert(message: "리뷰 등록에 실패했습니다: \(error.localizedDescription)")
                }
            }
        }
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
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
    
    private func showAlert(message: String, completion: ((UIAlertAction) -> Void)? = nil) {
        let alert = UIAlertController(
            title: "알림",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default, handler: completion))
        present(alert, animated: true)
    }
}

