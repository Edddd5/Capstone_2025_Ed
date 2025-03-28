//
//  WishlistDTO.swift
//  Market
//
//  Created by 장동혁 on 3/13/25.
//

import Foundation

struct Wishlist: Codable {
    let id: Int
    let userId: Int
    let postId: Int
    let post: Post?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case postId
        case post
    }
}

// Extension to Post to handle wishlist status
extension Post {
    // This will be used to track if a post is in the user's wishlist
    var isInWishlist: Bool {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.isInWishlistKey) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.isInWishlistKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

// Associated keys for the extension
private struct AssociatedKeys {
    static var isInWishlistKey = "isInWishlistKey"
}
