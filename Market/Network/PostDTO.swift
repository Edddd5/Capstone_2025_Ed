//
//  PostDTO.swift
//  Market
//
//  Created by 장동혁 on 2/28/25.
//

import Foundation

// MARK: - Post Model
struct Post: Codable {
    let id: Int
    let title: String
    let content: String
    let price: Int
    let place: String?
    let status: Int
    let viewCount: Int
    let wishlistCount: Int
    let createdAt: String
    let updatedAt: String
    let user: User?
    let images: [PostImage]?
    
    // 옵셔널 필드를 위한 초기화
    enum CodingKeys: String, CodingKey {
        case id, title, content, price, place, status
        case viewCount, wishlistCount, createdAt, updatedAt
        case user, images
    }
    
    // 이미지 URL 배열을 가져오는 계산 속성
    var imageUrls: [String]? {
        return images?.compactMap { $0.imageUrl }
    }
}

// MARK: - User Model
struct User: Codable {
    let id: Int
    let email: String
    let nickname: String
    let profileImageUrl: String?
}

// MARK: - PostImage Model
struct PostImage: Codable {
    let id: Int
    let imageUrl: String
    let sequence: Int
}

// MARK: - API Response
struct PageResponse<T: Codable>: Codable {
    let content: [T]
    let pageable: Pageable
    let totalElements: Int
    let totalPages: Int
    let last: Bool
    let size: Int
    let number: Int
    let sort: Sort
    let numberOfElements: Int
    let first: Bool
    let empty: Bool
    
    struct Pageable: Codable {
        let pageNumber: Int
        let pageSize: Int
        let sort: Sort
        let offset: Int
        let paged: Bool
        let unpaged: Bool
    }
    
    struct Sort: Codable {
        let empty: Bool
        let sorted: Bool
        let unsorted: Bool
    }
}
