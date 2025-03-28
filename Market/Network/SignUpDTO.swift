//
//  SignUpDTO.swift
//  Market
//
//  Created by 장동혁 on 2/6/25.
//

struct SignUpDTO: Codable {
    let email: String
    let password: String
    let nickname: String
    
    enum CodingKeys: String, CodingKey {
        case email = "email"
        case password = "password"
        case nickname = "nickname"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(email, forKey: .email)
        try container.encode(password, forKey: .password)
        try container.encode(nickname, forKey: .nickname)
    }
}
