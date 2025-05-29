//
//  Message.swift
//  Market
//
//  Created by 장동혁 on 5/27/25.
//

import Foundation

struct Message {
    let id: Int
    let senderId: Int
    let text: String
    let timestamp: Date
    let isRead: Bool
    
    // 내가 보낸 메시지인지 여부
    var isFromMe: Bool {
        guard let myUserId = UserDefaults.standard.object(forKey: "userId") as? Int else {
            return false
        }
        return senderId == myUserId
    }
}
