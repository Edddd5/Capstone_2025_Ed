//
//  ChatRoomCell.swift
//  Market
//
//  Created on 5/19/25.
//

import UIKit

class ChatRoomCell: UITableViewCell {
    
    // MARK: - UI Components
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .lightGray
        imageView.layer.cornerRadius = 20
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let lastMessageLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .darkGray
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .gray
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let unreadBadge: UIView = {
        let view = UIView()
        view.backgroundColor = .systemRed
        view.layer.cornerRadius = 10
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let unreadCountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Initializers
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupViews() {
        // 기본 설정
        accessoryType = .disclosureIndicator
        selectionStyle = .default
        
        // 서브뷰 추가 (상품 정보 관련 제거됨)
        contentView.addSubview(profileImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(lastMessageLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(unreadBadge)
        unreadBadge.addSubview(unreadCountLabel)
        
        NSLayoutConstraint.activate([
            // 프로필 이미지
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            profileImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 40),
            profileImageView.heightAnchor.constraint(equalToConstant: 40),
            
            // 이름 레이블
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -8),
            
            // 마지막 메시지 레이블 (아래쪽 제약조건 수정)
            lastMessageLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            lastMessageLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            lastMessageLabel.trailingAnchor.constraint(equalTo: unreadBadge.leadingAnchor, constant: -8),
            lastMessageLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            
            // 시간 레이블
            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            timeLabel.topAnchor.constraint(equalTo: nameLabel.topAnchor),
            timeLabel.widthAnchor.constraint(equalToConstant: 60),
            
            // 안 읽은 메시지 뱃지
            unreadBadge.trailingAnchor.constraint(equalTo: timeLabel.trailingAnchor),
            unreadBadge.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 4),
            unreadBadge.widthAnchor.constraint(equalToConstant: 20),
            unreadBadge.heightAnchor.constraint(equalToConstant: 20),
            
            // 안 읽은 메시지 카운트 레이블
            unreadCountLabel.centerXAnchor.constraint(equalTo: unreadBadge.centerXAnchor),
            unreadCountLabel.centerYAnchor.constraint(equalTo: unreadBadge.centerYAnchor),
            unreadCountLabel.widthAnchor.constraint(equalTo: unreadBadge.widthAnchor),
            unreadCountLabel.heightAnchor.constraint(equalTo: unreadBadge.heightAnchor)
        ])
    }
    
    // MARK: - Configuration
    func configure(with chatRoom: ChatRoomModel) {
        nameLabel.text = chatRoom.partnerName
        
        lastMessageLabel.text = chatRoom.lastMessage ?? "새로운 채팅방이 생성되었습니다."
        
        if let lastMessageDate = chatRoom.lastMessageDate {
            timeLabel.text = formatDate(lastMessageDate)
        } else {
            timeLabel.text = ""
        }
        
        
        // 프로필 이미지 로드 (수정된 URL 패턴)
        if let profileImageUrl = chatRoom.partnerProfileImageUrl,
           !profileImageUrl.isEmpty,
           let url = URL(string: "https://hanlumi.co.kr/images/profile/\(profileImageUrl)") {
            loadImage(from: url, to: profileImageView)
        } else {
            profileImageView.image = UIImage(systemName: "person.circle.fill")
            profileImageView.tintColor = .systemGray4
        }
        
        if chatRoom.unreadCount > 0 {
            unreadBadge.isHidden = false
            unreadCountLabel.text = chatRoom.unreadCount > 9 ? "9+" : "\(chatRoom.unreadCount)"
        } else {
            unreadBadge.isHidden = true
        }
    }
    
    // 날짜 포맷팅 헬퍼 메서드
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "어제"
        } else {
            // 그 외에는 월/일 표시
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd"
            return formatter.string(from: date)
        }
    }
    
    private func loadImage(from url: URL, to imageView: UIImageView) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error loading image: \(error.localizedDescription)")
                return
            }
            
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    imageView.image = image
                }
            }
        }.resume()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        profileImageView.image = nil
        nameLabel.text = nil
        lastMessageLabel.text = nil
        timeLabel.text = nil
        unreadCountLabel.text = nil
        unreadBadge.isHidden = true
    }
}
