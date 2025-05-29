//
//  ReviewResponse.swift
//  Market
//
//  Created by 장동혁 on 5/30/25.
//

import Foundation

// MARK: - Response Models
struct ReviewResponse: Codable {
    let id: Int
    let post: PostInfo?
    let reviewer: UserInfo
    let reviewee: UserInfo
    let rating: Int
    let comment: String
    
    struct PostInfo: Codable {
        let id: Int
        let title: String
        let content: String
        let user: UserInfo
        let createdAt: String
        let updatedAt: String
        let price: Int
        let viewCount: Int
        let wishlistCount: Int
        let status: Int
        let images: [ImageInfo]?
        
        struct ImageInfo: Codable {
            let id: Int
            let imageUrl: String
            let sequence: Int
        }
    }
    
    struct UserInfo: Codable {
        let id: Int
        let email: String
        let nickname: String
        let profileImageUrl: String?
        let rating: Double
    }
    
    // 편의 속성들
    var reviewerNickname: String { reviewer.nickname }
    var revieweeNickname: String { reviewee.nickname }
    var createdAt: String {
        // 서버 응답에 createdAt이 없으므로 현재 시간을 문자열로 반환
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd' 'HH:mm:ss"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: Date())
    }
}
