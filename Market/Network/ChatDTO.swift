//
//  ChatDTO.swift
//  Market
//
//  Created on 5/20/25.
//

import Foundation

// MARK: - 채팅방 관련 DTO
struct ChatRoomResponse: Codable {
    let id: Int
    let user: ChatUserDTO
    let post: ChatPostDTO
    let lastMessage: String?
    let lastMessageTime: String?
    let unreadCount: Int
    
    // 서버 응답(ServerChatRoom)에서 변환
    init(from serverChatRoom: ServerChatRoom) {
        self.id = serverChatRoom.id
        
        let currentUserId = UserDefaults.standard.integer(forKey: "userId")
        
        if serverChatRoom.seller.id == currentUserId {
            self.user = ChatUserDTO(
                id: serverChatRoom.buyer.id,
                nickname: serverChatRoom.buyer.nickname ?? "구매자",
                profileImageUrl: serverChatRoom.buyer.profileImageUrl,
                email: serverChatRoom.buyer.email,
                rating: serverChatRoom.buyer.rating
            )
        } else {
            self.user = ChatUserDTO(
                id: serverChatRoom.seller.id,
                nickname: serverChatRoom.seller.nickname ?? "판매자",
                profileImageUrl: serverChatRoom.seller.profileImageUrl,
                email: serverChatRoom.seller.email,
                rating: serverChatRoom.seller.rating
            )
        }
        
        self.post = ChatPostDTO(
            id: serverChatRoom.postId,
            title: "상품",
            imageUrl: nil
        )
        
        self.lastMessage = nil
        self.lastMessageTime = serverChatRoom.createdAt
        self.unreadCount = 0
    }
    
    // JSON Dictionary에서 직접 변환
    init(from directServerResponse: [String: Any]) {
        self.id = directServerResponse["id"] as? Int ?? 0
        
        let currentUserId = UserDefaults.standard.integer(forKey: "userId")
        
        let sellerData = directServerResponse["seller"] as? [String: Any] ?? [:]
        let buyerData = directServerResponse["buyer"] as? [String: Any] ?? [:]
        
        let sellerId = sellerData["id"] as? Int ?? 0
        let sellerNickname = sellerData["nickname"] as? String ?? "판매자"
        let sellerProfileUrl = sellerData["profileImageUrl"] as? String
        let sellerEmail = sellerData["email"] as? String
        let sellerRating = sellerData["rating"] as? Double
        
        let buyerId = buyerData["id"] as? Int ?? 0
        let buyerNickname = buyerData["nickname"] as? String ?? "구매자"
        let buyerProfileUrl = buyerData["profileImageUrl"] as? String
        let buyerEmail = buyerData["email"] as? String
        let buyerRating = buyerData["rating"] as? Double
        
        if sellerId == currentUserId {
            self.user = ChatUserDTO(
                id: buyerId,
                nickname: buyerNickname,
                profileImageUrl: buyerProfileUrl,
                email: buyerEmail,
                rating: buyerRating
            )
        } else {
            self.user = ChatUserDTO(
                id: sellerId,
                nickname: sellerNickname,
                profileImageUrl: sellerProfileUrl,
                email: sellerEmail,
                rating: sellerRating
            )
        }
        
        let postId = directServerResponse["postId"] as? Int ?? 0
        self.post = ChatPostDTO(
            id: postId,
            title: "상품",
            imageUrl: nil
        )
        
        self.lastMessage = nil
        self.lastMessageTime = directServerResponse["createdAt"] as? String
        self.unreadCount = 0
    }
    
    // 기본 생성자
    init(id: Int, user: ChatUserDTO, post: ChatPostDTO, lastMessage: String?, lastMessageTime: String?, unreadCount: Int) {
        self.id = id
        self.user = user
        self.post = post
        self.lastMessage = lastMessage
        self.lastMessageTime = lastMessageTime
        self.unreadCount = unreadCount
    }
}

struct ChatUserDTO: Codable {
    let id: Int
    let nickname: String
    let profileImageUrl: String?
    let email: String?
    let rating: Double?
    
    init(id: Int, nickname: String, profileImageUrl: String?, email: String? = nil, rating: Double? = nil) {
        self.id = id
        self.nickname = nickname
        self.profileImageUrl = profileImageUrl
        self.email = email
        self.rating = rating
    }
}

struct ChatPostDTO: Codable {
    let id: Int
    let title: String
    let imageUrl: String?
}

struct CreateChatRoomRequest: Codable {
    let postId: Int
}

// MARK: - 메시지 관련 DTO
struct MessageResponse: Codable {
    let id: Int
    let chatRoomId: Int
    let senderId: Int
    let content: String
    let createdAt: String
    let isRead: Bool
    
    // ChatMessageDTO로부터 변환
    init(from chatMessageDTO: ChatMessageDTO, chatRoomId: Int) {
        self.id = chatMessageDTO.id ?? Int.random(in: 1000...9999)
        self.chatRoomId = chatRoomId
        self.senderId = chatMessageDTO.sender?.id ?? 0
        self.content = chatMessageDTO.content
        self.createdAt = chatMessageDTO.sentAt ?? ISO8601DateFormatter().string(from: Date())
        self.isRead = true
    }
    
    // JSON Dictionary에서 직접 변환
    init(from json: [String: Any], chatRoomId: Int) {
        self.id = json["id"] as? Int ?? Int.random(in: 1000...9999)
        self.chatRoomId = chatRoomId
        self.content = json["content"] as? String ?? ""
        self.createdAt = json["sentAt"] as? String ?? json["timestamp"] as? String ?? ISO8601DateFormatter().string(from: Date())
        self.isRead = true
        
        if let directSenderId = json["senderId"] as? Int {
            self.senderId = directSenderId
        } else if let sender = json["sender"] as? [String: Any], let senderIdFromSender = sender["id"] as? Int {
            self.senderId = senderIdFromSender
        } else {
            self.senderId = 0
        }
    }
    
    // 기본 생성자
    init(id: Int, chatRoomId: Int, senderId: Int, content: String, createdAt: String, isRead: Bool) {
        self.id = id
        self.chatRoomId = chatRoomId
        self.senderId = senderId
        self.content = content
        self.createdAt = createdAt
        self.isRead = isRead
    }
}

struct SendMessageRequest: Codable {
    let content: String
}

// MARK: - 웹소켓 메시지 DTO
struct ChatMessageDTO: Codable {
    var id: Int?
    var content: String
    var sender: SenderDTO?
    var sentAt: String?
    var chatRoomId: Int?
    
    struct SenderDTO: Codable {
        var id: Int
        var nickname: String?
        var profileImageUrl: String?
        var email: String?
        var rating: Double?
        
        enum CodingKeys: String, CodingKey {
            case id, nickname, profileImageUrl, email, rating
        }
    }
    
    // 유연한 디코딩
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.content = try container.decode(String.self, forKey: .content)
        self.id = try container.decodeIfPresent(Int.self, forKey: .id)
        self.sender = try container.decodeIfPresent(SenderDTO.self, forKey: .sender)
        self.sentAt = try container.decodeIfPresent(String.self, forKey: .sentAt)
        self.chatRoomId = try container.decodeIfPresent(Int.self, forKey: .chatRoomId)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(content, forKey: .content)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(sender, forKey: .sender)
        try container.encodeIfPresent(sentAt, forKey: .sentAt)
        try container.encodeIfPresent(chatRoomId, forKey: .chatRoomId)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, content, sender, sentAt, chatRoomId
    }
}

// MARK: - 서버 응답 모델
struct ServerChatRoom: Codable {
    let id: Int
    let postId: Int
    let seller: ServerUser
    let buyer: ServerUser
    let createdAt: String?
    
    struct ServerUser: Codable {
        let id: Int
        let nickname: String?
        let profileImageUrl: String?
        let email: String?
        let rating: Double?
        
        enum CodingKeys: String, CodingKey {
            case id, nickname, profileImageUrl, email, rating
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, postId, seller, buyer, createdAt
    }
}

extension MessageResponse {
    func toMessage() -> Message? {
        let dateFormatter = ISO8601DateFormatter()
        guard let date = dateFormatter.date(from: createdAt) else {
            return nil
        }
        
        return Message(
            id: id,
            senderId: senderId,
            text: content,
            timestamp: date,
            isRead: isRead
        )
    }
}

extension ChatMessageDTO {
    func toMessageResponse(chatRoomId: Int) -> MessageResponse {
        return MessageResponse(
            id: id ?? Int.random(in: 1000...9999),
            chatRoomId: chatRoomId,
            senderId: sender?.id ?? 0,
            content: content,
            createdAt: sentAt ?? ISO8601DateFormatter().string(from: Date()),
            isRead: true
        )
    }
}
