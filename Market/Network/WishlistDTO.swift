//
//  WishlistDTO.swift
//  Market
//
//  Created by 장동혁 on 3/13/25.
//

import Foundation

// 서버 응답과 정확히 일치하는 구조체
struct WishlistResponse: Codable {
    let id: Int
    let user: UserInfo
    let post: Post
    
    struct UserInfo: Codable {
        let id: Int
        let email: String
        let nickname: String
        let profileImageUrl: String?
        let rating: Int?
    }
    
    // WishlistResponse를 Wishlist로 변환
    func toWishlist() -> Wishlist {
        return Wishlist(id: id, userId: user.id, postId: post.id, post: post)
    }
}

// 앱 내부에서 사용하는 Wishlist 구조체
struct Wishlist: Codable {
    let id: Int
    let userId: Int?
    let postId: Int
    let post: Post?
    
    // 기본 생성자
    init(id: Int, userId: Int?, postId: Int, post: Post?) {
        self.id = id
        self.userId = userId
        self.postId = postId
        self.post = post
    }
}

// 직접 서버 응답을 Wishlist 배열로 변환하는 확장
extension Array where Element == WishlistResponse {
    func toWishlistArray() -> [Wishlist] {
        return self.map { $0.toWishlist() }
    }
}
