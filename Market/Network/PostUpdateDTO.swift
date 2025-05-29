//
//  PostUpdateDTO.swift
//  Market
//
//  Created by 장동혁 on 5/8/25.
//

import Foundation

// MARK: - 게시물 수정 요청 DTO
struct PostUpdateDTO: Codable {
    let title: String
    let content: String
    let price: Int
    let place: String
    let status: Int
    let imageUrls: [String]
    
    // 게시물 수정에 필요한 데이터 모델 생성
    init(title: String, content: String, price: Int, place: String, status: Int, imageUrls: [String]) {
        self.title = title
        self.content = content
        self.price = price
        self.place = place
        self.status = status
        self.imageUrls = imageUrls
    }
    
    // Post 모델에서 직접 DTO 생성
    static func fromPost(_ post: Post, status: Int) -> PostUpdateDTO {
        return PostUpdateDTO(
            title: post.title,
            content: post.content,
            price: post.price,
            place: post.place ?? "",
            status: status,
            imageUrls: post.imageUrls ?? []
        )
    }
}
