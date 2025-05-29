//
//  ChatRoomModel.swift
//  Market
//
//  Created on 5/22/25.
//

import Foundation

// MARK: - 앱 내에서 사용하는 채팅방 모델
struct ChatRoomModel {
    let id: Int
    let partnerName: String
    let partnerProfileImageUrl: String?
    let lastMessage: String?
    let lastMessageDate: Date?
    let unreadCount: Int
    let postTitle: String
    let postImageUrl: String?
}

extension ChatRoomResponse {
    func toChatRoomModel() -> ChatRoomModel {
        // ISO8601 형식의 날짜 문자열을 Date로 변환
        let dateFormatter = ISO8601DateFormatter()
        let date = self.lastMessageTime.flatMap { dateFormatter.date(from: $0) }
        
        return ChatRoomModel(
            id: self.id,
            partnerName: self.user.nickname,
            partnerProfileImageUrl: self.user.profileImageUrl,
            lastMessage: self.lastMessage,
            lastMessageDate: date,
            unreadCount: self.unreadCount,
            postTitle: self.post.title,
            postImageUrl: self.post.imageUrl
        )
    }
}
