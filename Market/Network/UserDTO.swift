//
//  UserDTO.swift
//  Market
//
//  Created by 장동혁 on 2/13/25.
//

//
//  UserDTO.swift
//  Market
//

import Foundation

struct UserDTO: Codable {
    let userId: Int
    let email: String
    let nickname: String
    
    // 서버 응답의 다양한 필드명에 대응하기 위한 CodingKeys
    enum CodingKeys: String, CodingKey {
        case userId // 서버가 "userId"를 사용하는 경우
        case id // 서버가 "id"를 사용하는 경우
        case email
        case nickname
        case name // 서버가 "name"을 "nickname" 대신 사용하는 경우
    }
    
    // 복잡한 디코딩 로직을 위한 사용자 정의 이니셜라이저
    init(from decoder: Decoder) throws {
        print("🔄 UserDTO: 디코딩 시작")
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // userId 디코딩 - "userId" 또는 "id" 필드에서 시도
        if let userId = try? container.decode(Int.self, forKey: .userId) {
            self.userId = userId
            print("✅ UserDTO: userId 필드에서 디코딩 성공: \(userId)")
        } else if let id = try? container.decode(Int.self, forKey: .id) {
            self.userId = id
            print("✅ UserDTO: id 필드에서 디코딩 성공: \(id)")
        } else if let userIdString = try? container.decode(String.self, forKey: .userId),
                  let userIdInt = Int(userIdString) {
            // 문자열로 된 userId 처리
            self.userId = userIdInt
            print("✅ UserDTO: 문자열 userId 필드에서 변환 성공: \(userIdString) -> \(userIdInt)")
        } else if let idString = try? container.decode(String.self, forKey: .id),
                  let idInt = Int(idString) {
            // 문자열로 된 id 처리
            self.userId = idInt
            print("✅ UserDTO: 문자열 id 필드에서 변환 성공: \(idString) -> \(idInt)")
        } else {
            print("❌ UserDTO: userId/id 필드를 찾을 수 없거나 파싱할 수 없음")
            throw DecodingError.valueNotFound(
                Int.self,
                DecodingError.Context(
                    codingPath: [CodingKeys.userId],
                    debugDescription: "UserId 또는 id 필드를 찾을 수 없음"
                )
            )
        }
        
        // 이메일 디코딩
        do {
            self.email = try container.decode(String.self, forKey: .email)
            print("✅ UserDTO: email 디코딩 성공: \(email)")
        } catch {
            print("❌ UserDTO: email 디코딩 실패: \(error)")
            throw error
        }
        
        // 닉네임 디코딩 - "nickname" 또는 "name" 필드에서 시도
        if let nickname = try? container.decode(String.self, forKey: .nickname) {
            self.nickname = nickname
            print("✅ UserDTO: nickname 필드에서 디코딩 성공: \(nickname)")
        } else if let name = try? container.decode(String.self, forKey: .name) {
            self.nickname = name
            print("✅ UserDTO: name 필드에서 디코딩 성공: \(name)")
        } else {
            print("❌ UserDTO: nickname/name 필드를 찾을 수 없음")
            throw DecodingError.valueNotFound(
                String.self,
                DecodingError.Context(
                    codingPath: [CodingKeys.nickname],
                    debugDescription: "nickname 또는 name 필드를 찾을 수 없음"
                )
            )
        }
        
        print("✅ UserDTO: 디코딩 완료 - userId: \(userId), email: \(email), nickname: \(nickname)")
    }
    
    // 인코딩을 위한 메서드 (서버로 데이터 전송 시 사용)
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userId, forKey: .userId)
        try container.encode(email, forKey: .email)
        try container.encode(nickname, forKey: .nickname)
    }
    
    // 테스트 및 디버깅을 위한 메서드
    func description() -> String {
        return "UserDTO(userId: \(userId), email: \(email), nickname: \(nickname))"
    }
}
