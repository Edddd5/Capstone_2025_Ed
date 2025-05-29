//
//  MessageCell.swift
//  Market
//
//  Created on 5/19/25.
//

import UIKit

class MessageCell: UITableViewCell {
    
    // MARK: - UI Components
    private let messageContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .gray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Properties
    private var messageContainerLeadingConstraint: NSLayoutConstraint!
    private var messageContainerTrailingConstraint: NSLayoutConstraint!
    private var timeLabelLeadingConstraint: NSLayoutConstraint!
    private var timeLabelTrailingConstraint: NSLayoutConstraint!
    
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
        backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        selectionStyle = .none
        
        // 서브뷰 추가
        contentView.addSubview(messageContainer)
        messageContainer.addSubview(messageLabel)
        contentView.addSubview(timeLabel)
        
        // 제약 조건 생성 (나중에 활성화/비활성화할 제약조건은 변수에 저장)
        messageContainerLeadingConstraint = messageContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        messageContainerTrailingConstraint = messageContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        
        timeLabelLeadingConstraint = timeLabel.leadingAnchor.constraint(equalTo: messageContainer.trailingAnchor, constant: 4)
        timeLabelTrailingConstraint = timeLabel.trailingAnchor.constraint(equalTo: messageContainer.leadingAnchor, constant: -4)
        
        // 공통 제약 조건 활성화
        NSLayoutConstraint.activate([
            messageContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            messageContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            messageContainer.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.7),
            
            messageLabel.topAnchor.constraint(equalTo: messageContainer.topAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: messageContainer.leadingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: messageContainer.trailingAnchor, constant: -12),
            messageLabel.bottomAnchor.constraint(equalTo: messageContainer.bottomAnchor, constant: -8),
            
            timeLabel.bottomAnchor.constraint(equalTo: messageContainer.bottomAnchor, constant: -2)
        ])
    }
    
    // MARK: - Configuration
    func configure(with message: Message) {
        messageLabel.text = message.text
        timeLabel.text = formatTime(message.timestamp)
        
        // 내 메시지인지 상대방 메시지인지에 따라 스타일 적용
        if message.isFromMe {
            setupAsSentMessage(isRead: message.isRead)
        } else {
            setupAsReceivedMessage()
        }
    }
    
    private func setupAsSentMessage(isRead: Bool) {
        // 내 메시지 스타일 적용
        messageContainer.backgroundColor = UIColor.systemBlue
        messageLabel.textColor = .white
        
        // 정렬 설정 (오른쪽)
        messageContainerLeadingConstraint.isActive = false
        messageContainerTrailingConstraint.isActive = true
        
        timeLabelLeadingConstraint.isActive = false
        timeLabelTrailingConstraint.isActive = true
    }
    
    private func setupAsReceivedMessage() {
        // 상대방 메시지 스타일 적용
        messageContainer.backgroundColor = .white
        messageLabel.textColor = .black
        
        // 정렬 설정 (왼쪽)
        messageContainerTrailingConstraint.isActive = false
        messageContainerLeadingConstraint.isActive = true
        
        timeLabelTrailingConstraint.isActive = false
        timeLabelLeadingConstraint.isActive = true
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // 재사용 시 초기화
        messageLabel.text = nil
        timeLabel.text = nil
        
        // 모든 제약조건 비활성화
        messageContainerLeadingConstraint.isActive = false
        messageContainerTrailingConstraint.isActive = false
        timeLabelLeadingConstraint.isActive = false
        timeLabelTrailingConstraint.isActive = false
    }
}
