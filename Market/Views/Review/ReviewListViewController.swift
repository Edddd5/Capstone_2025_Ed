//
//  ReviewListViewController.swift
//  Market
//
//  Created by 장동혁 on 5/30/25.
//

import UIKit

struct ReviewItem: Codable {
    let reviewId: Int
    let rating: Int
    let comment: String
    let reviewerNickname: String?
    let revieweeNickname: String?
    let createdAt: String
    let isReceived: Bool // true: 받은 리뷰, false: 보낸 리뷰
}

class ReviewListViewController: UIViewController {
    
    // UI 컴포넌트
    private let segmentedControl: UISegmentedControl = {
        let items = ["받은 리뷰", "보낸 리뷰"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        control.backgroundColor = .systemBackground
        control.selectedSegmentTintColor = .systemBlue
        return control
    }()
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .white
        tableView.separatorStyle = .singleLine
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        return tableView
    }()
    
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "리뷰가 없습니다"
        label.font = .systemFont(ofSize: 16)
        label.textColor = .gray
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()
    
    private var receivedReviews: [ReviewItem] = []
    private var sentReviews: [ReviewItem] = []
    private var isLoading = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupNavigationBar()
        setupUI()
        setupTableView()
        loadReviews()
    }
    
    private func setupNavigationBar() {
        title = "리뷰 관리"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
    }
    
    private func setupUI() {
        [segmentedControl, tableView, emptyLabel].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            segmentedControl.heightAnchor.constraint(equalToConstant: 32),
            
            tableView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ReviewTableViewCell.self, forCellReuseIdentifier: "ReviewCell")
    }
    
    private func loadReviews() {
        guard !isLoading else { return }
        
        guard let token = UserDefaults.standard.string(forKey: "userToken") else {
            showAlert(message: "로그인이 필요합니다.")
            return
        }
        
        isLoading = true
        showLoadingIndicator()
        
        let group = DispatchGroup()
        var receivedError: Error?
        var sentError: Error?
        
        // 받은 리뷰 로드
        group.enter()
        NetworkManager.shared.getReceivedReviews(token: token) { [weak self] result in
            switch result {
            case .success(let reviews):
                self?.receivedReviews = reviews
            case .failure(let error):
                receivedError = error
            }
            group.leave()
        }
        
        // 보낸 리뷰 로드
        group.enter()
        NetworkManager.shared.getSentReviews(token: token) { [weak self] result in
            switch result {
            case .success(let reviews):
                self?.sentReviews = reviews
            case .failure(let error):
                sentError = error
            }
            group.leave()
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.hideLoadingIndicator()
            self?.isLoading = false
            
            if let error = receivedError ?? sentError {
                self?.showAlert(message: "리뷰를 불러오는데 실패했습니다: \(error.localizedDescription)")
            }
            
            self?.updateUI()
        }
    }
    
    @objc private func segmentChanged() {
        updateUI()
    }
    
    private func updateUI() {
        let currentReviews = segmentedControl.selectedSegmentIndex == 0 ? receivedReviews : sentReviews
        
        if currentReviews.isEmpty {
            emptyLabel.text = segmentedControl.selectedSegmentIndex == 0 ? "받은 리뷰가 없습니다" : "보낸 리뷰가 없습니다"
            emptyLabel.isHidden = false
            tableView.isHidden = true
        } else {
            emptyLabel.isHidden = true
            tableView.isHidden = false
            tableView.reloadData()
        }
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
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
        let alert = UIAlertController(
            title: "알림",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - TableView DataSource & Delegate
extension ReviewListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return segmentedControl.selectedSegmentIndex == 0 ? receivedReviews.count : sentReviews.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReviewCell", for: indexPath) as! ReviewTableViewCell
        let reviews = segmentedControl.selectedSegmentIndex == 0 ? receivedReviews : sentReviews
        let review = reviews[indexPath.row]
        cell.configure(with: review)
        return cell
    }
}

// MARK: - ReviewTableViewCell
class ReviewTableViewCell: UITableViewCell {
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        return view
    }()
    
    private let userLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        return label
    }()
    
    private let ratingStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 2
        stackView.distribution = .fillEqually // 균등하게 분배
        stackView.alignment = .center
        return stackView
    }()
    
    private let commentLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .tertiaryLabel
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        [userLabel, ratingStackView, commentLabel, dateLabel].forEach {
            containerView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            userLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            userLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            userLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            ratingStackView.topAnchor.constraint(equalTo: userLabel.bottomAnchor, constant: 8),
            ratingStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            ratingStackView.heightAnchor.constraint(equalToConstant: 16),
            ratingStackView.widthAnchor.constraint(equalToConstant: 88), // 5개 별 * 16px + 4개 간격 * 2px
            
            commentLabel.topAnchor.constraint(equalTo: ratingStackView.bottomAnchor, constant: 8),
            commentLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            commentLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            dateLabel.topAnchor.constraint(equalTo: commentLabel.bottomAnchor, constant: 8),
            dateLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            dateLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            dateLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with review: ReviewItem) {
        userLabel.text = review.isReceived ?
        (review.reviewerNickname ?? "익명") :
        (review.revieweeNickname ?? "익명")
        
        setupRatingStars(rating: review.rating)
        commentLabel.text = review.comment
        dateLabel.text = review.createdAt
    }
    
    private func setupRatingStars(rating: Int) {
        // 기존 별점 제거
        ratingStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // 새로운 별점 추가
        for i in 1...5 {
            let starImageView = UIImageView()
            starImageView.image = UIImage(systemName: i <= rating ? "star.fill" : "star")
            starImageView.tintColor = .systemYellow
            starImageView.contentMode = .scaleAspectFit
            
            // 모든 별의 크기를 동일하게 설정
            starImageView.translatesAutoresizingMaskIntoConstraints = false
            starImageView.widthAnchor.constraint(equalToConstant: 16).isActive = true
            starImageView.heightAnchor.constraint(equalToConstant: 16).isActive = true
            
            ratingStackView.addArrangedSubview(starImageView)
        }
    }
}
