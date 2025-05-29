//
//  NetworkManager.swift
//  Market
//
//  Created by 장동혁 on 2/6/25.
//

import Foundation
import UIKit

class NetworkManager {
    static let shared = NetworkManager()
    private let baseURL = "https://hanlumi.co.kr"
    private let wsBaseURL = "wss://hanlumi.co.kr"
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var messageHandler: ((MessageResponse) -> Void)?
    private var currentChatRoomId: Int?
    private var isConnected: Bool = false
        
    private init() {}
    
    // MARK: - Post API Methods
    
    // 게시물 목록 가져오기
    func fetchPosts(page: Int, size: Int, completion: @escaping (Result<PageResponse<Post>, Error>) -> Void) {
        let urlString = "\(baseURL)/api/posts?page=\(page)&size=\(size)"
        guard let url = URL(string: urlString) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // 인증 토큰 추가
        if let token = UserDefaults.standard.string(forKey: "userToken") {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching posts: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NetworkError.invalidResponse))
                return
            }
            
            // 인증 오류 처리
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                completion(.failure(NetworkError.authenticationRequired))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(NetworkError.serverError(httpResponse.statusCode)))
                return
            }
            
            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }
            
            // HTML 응답인지 확인 (로그인 페이지로 리디렉션된 경우)
            if let contentType = httpResponse.allHeaderFields["Content-Type"] as? String,
               contentType.contains("text/html") {
                completion(.failure(NetworkError.authenticationRequired))
                return
            }
            
            do {
                // 디버깅용 응답 출력
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response data (first 200 chars): \(responseString.prefix(200))")
                }
                
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .useDefaultKeys
                decoder.dateDecodingStrategy = .iso8601
                
                let pageResponse = try decoder.decode(PageResponse<Post>.self, from: data)
                completion(.success(pageResponse))
            } catch {
                print("Error decoding response: \(error)")
                
                // 디코딩 오류 상세 정보
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        print("Key not found: \(key), context: \(context.debugDescription)")
                    case .valueNotFound(let type, let context):
                        print("Value not found: \(type), context: \(context.debugDescription)")
                    case .typeMismatch(let type, let context):
                        print("Type mismatch: \(type), context: \(context.debugDescription)")
                    case .dataCorrupted(let context):
                        print("Data corrupted: \(context.debugDescription)")
                    @unknown default:
                        print("Unknown decoding error")
                    }
                }
                
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    // 단일 게시물 조회
    func fetchPost(id: Int, completion: @escaping (Result<Post, Error>) -> Void) {
        let urlString = "\(baseURL)/api/post/\(id)"
        guard let url = URL(string: urlString) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // 인증 토큰 추가
        if let token = UserDefaults.standard.string(forKey: "userToken") {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NetworkError.invalidResponse))
                return
            }
            
            // 인증 오류 처리
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                completion(.failure(NetworkError.authenticationRequired))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(NetworkError.serverError(httpResponse.statusCode)))
                return
            }
            
            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let post = try decoder.decode(Post.self, from: data)
                completion(.success(post))
            } catch {
                print("Error decoding post: \(error)")
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    // 게시물 작성
    func createPost(title: String, content: String, price: Int, place: String?, images: [Data]?, completion: @escaping (Result<Post, Error>) -> Void) {
        let urlString = "\(baseURL)/api/post"
        print("🔄 게시물 생성 요청 URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ 잘못된 URL: \(urlString)")
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        // 토큰 확인
        guard let token = UserDefaults.standard.string(forKey: "userToken") else {
            print("❌ 인증 토큰 없음")
            completion(.failure(NetworkError.authenticationRequired))
            return
        }
        
        print("✅ 인증 토큰 확인: \(token.prefix(15))...")
        
        // multipart/form-data 경계 문자열 생성
        let boundary = "Boundary-\(UUID().uuidString)"
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // 타임아웃 값 늘리기 (이미지 업로드 시간 고려)
        request.timeoutInterval = 60.0
        
        var body = Data()
        
        // 요청 파라미터 로깅
        print("📤 전송 파라미터:")
        print("   - title: \(title)")
        print("   - content: \(content.prefix(50))...")
        print("   - price: \(price)")
        print("   - place: \(place ?? "없음")")
        
        // 필수 필드 추가
        addFormField(to: &body, boundary: boundary, name: "title", value: title)
        addFormField(to: &body, boundary: boundary, name: "content", value: content)
        addFormField(to: &body, boundary: boundary, name: "price", value: "\(price)")
        
        // 위치 필드 추가 (옵셔널)
        if let place = place, !place.isEmpty {
            addFormField(to: &body, boundary: boundary, name: "place", value: place)
        } else {
            // place가 null인 경우 빈 문자열로 전송
            addFormField(to: &body, boundary: boundary, name: "place", value: "")
        }
        
        // 이미지 추가 - images 파라미터 이름 명확히 지정
        if let images = images, !images.isEmpty {
            print("📤 이미지 \(images.count)개 첨부")
            
            for (index, imageData) in images.enumerated() {
                let imageSizeKB = Double(imageData.count) / 1024.0
                print("   - 이미지 #\(index+1): \(String(format: "%.1f", imageSizeKB))KB")
                
                // 'images' 이름을 사용하여 파일 추가 (서버 컨트롤러와 일치)
                addImageField(to: &body, boundary: boundary, name: "images", fileName: "image\(index).jpg", mimeType: "image/jpeg", data: imageData)
            }
        } else {
            print("📤 첨부된 이미지 없음")
        }
        
        // 경계 종료
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        // 요청 본문 크기 확인 및 로깅
        let bodySizeMB = Double(body.count) / (1024.0 * 1024.0)
        print("📤 요청 본문 크기: \(String(format: "%.2f", bodySizeMB))MB")
        
        request.httpBody = body
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ 네트워크 오류: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ 올바르지 않은 HTTP 응답")
                completion(.failure(NetworkError.invalidResponse))
                return
            }
            
            print("ℹ️ HTTP 상태 코드: \(httpResponse.statusCode)")
            
            // HTTP 헤더 정보 출력 (디버깅용)
            print("ℹ️ HTTP 헤더:")
            httpResponse.allHeaderFields.forEach { key, value in
                print("   \(key): \(value)")
            }
            
            // 응답 본문 출력
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("ℹ️ 응답 본문:")
                print(responseString)
            }
            
            // 401/403 오류 처리
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                print("❌ 인증 오류 (코드: \(httpResponse.statusCode))")
                completion(.failure(NetworkError.authenticationRequired))
                return
            }
            
            // 상태 코드 확인
            guard (200...299).contains(httpResponse.statusCode) else {
                print("❌ 서버 오류 (코드: \(httpResponse.statusCode))")
                // 500 오류의 경우 응답 본문에서 추가 정보 확인 시도
                if httpResponse.statusCode == 500, let data = data, let errorMessage = String(data: data, encoding: .utf8) {
                    print("❌ 서버 오류 상세: \(errorMessage)")
                }
                completion(.failure(NetworkError.serverError(httpResponse.statusCode)))
                return
            }
            
            guard let data = data else {
                print("❌ 응답 데이터 없음")
                completion(.failure(NetworkError.noData))
                return
            }
            
            // JSON 파싱 및 디코딩
            do {
                // 서버 응답이 Post 객체와 일치하는지 확인 (디버깅용)
                if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    print("✅ JSON 구조:")
                    print(json.keys)
                }
                
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .useDefaultKeys
                let post = try decoder.decode(Post.self, from: data)
                print("✅ 게시물 생성 성공 (ID: \(post.id))")
                completion(.success(post))
            } catch {
                print("❌ JSON 디코딩 오류: \(error)")
                
                // 상세 디코딩 오류 정보
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, _):
                        print("   - 찾을 수 없는 키: \(key.stringValue)")
                    case .valueNotFound(let type, _):
                        print("   - 찾을 수 없는 값 타입: \(type)")
                    case .typeMismatch(let type, let context):
                        print("   - 타입 불일치: \(type)")
                        print("   - 경로: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                    case .dataCorrupted(let context):
                        print("   - 데이터 손상: \(context.debugDescription)")
                    @unknown default:
                        print("   - 알 수 없는 디코딩 오류")
                    }
                }
                
                completion(.failure(error))
            }
        }
        
        print("🔄 게시물 생성 요청 전송됨")
        task.resume()
    }
    
    // multipart/form-data 형식에 텍스트 필드 추가 헬퍼 메서드
    private func addFormField(to body: inout Data, boundary: String, name: String, value: String) {
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(value)\r\n".data(using: .utf8)!)
    }
    
    // multipart/form-data 형식에 이미지 필드 추가 헬퍼 메서드 (개선됨)
    private func addImageField(to body: inout Data, boundary: String, name: String, fileName: String, mimeType: String, data: Data) {
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)
    }
    
    func uploadProfileImage(imageData: Data, completion: @escaping (Result<String, Error>) -> Void) {
        let urlString = "\(baseURL)/images/profile/"
        print("🔄 프로필 이미지 업로드 요청 URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ 잘못된 URL: \(urlString)")
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        // 토큰 확인
        guard let token = UserDefaults.standard.string(forKey: "userToken") else {
            print("❌ 인증 토큰 없음")
            completion(.failure(NetworkError.authenticationRequired))
            return
        }
        
        print("✅ 인증 토큰 확인: \(token.prefix(15))...")
        
        // multipart/form-data 경계 문자열 생성
        let boundary = "Boundary-\(UUID().uuidString)"
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60.0
        
        var body = Data()
        
        // 이미지 데이터 추가
        let imageSizeKB = Double(imageData.count) / 1024.0
        print("📤 프로필 이미지 크기: \(String(format: "%.1f", imageSizeKB))KB")
        
        addImageField(to: &body, boundary: boundary, name: "profileImage", fileName: "profile.jpg", mimeType: "image/jpeg", data: imageData)
        
        // 경계 종료
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ 네트워크 오류: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ 올바르지 않은 HTTP 응답")
                completion(.failure(NetworkError.invalidResponse))
                return
            }
            
            print("ℹ️ HTTP 상태 코드: \(httpResponse.statusCode)")
            
            // 응답 본문 출력
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("ℹ️ 응답 본문: \(responseString)")
            }
            
            // 401/403 오류 처리
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                print("❌ 인증 오류 (코드: \(httpResponse.statusCode))")
                completion(.failure(NetworkError.authenticationRequired))
                return
            }
            
            // 상태 코드 확인
            guard (200...299).contains(httpResponse.statusCode) else {
                print("❌ 서버 오류 (코드: \(httpResponse.statusCode))")
                completion(.failure(NetworkError.serverError(httpResponse.statusCode)))
                return
            }
            
            guard let data = data else {
                print("❌ 응답 데이터 없음")
                completion(.failure(NetworkError.noData))
                return
            }
            
            // JSON 파싱
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let imageUrl = json["imageUrl"] as? String {
                    print("✅ 프로필 이미지 업로드 성공: \(imageUrl)")
                    completion(.success(imageUrl))
                } else if let responseString = String(data: data, encoding: .utf8) {
                    // 서버에서 단순 문자열로 응답하는 경우
                    print("✅ 프로필 이미지 업로드 성공: \(responseString)")
                    completion(.success(responseString))
                } else {
                    completion(.failure(NetworkError.invalidResponse))
                }
            } catch {
                print("❌ JSON 파싱 오류: \(error)")
                completion(.failure(error))
            }
        }
        
        print("🔄 프로필 이미지 업로드 요청 전송됨")
        task.resume()
    }
    
    // 회원정보 가져오기
    func getUserProfile(userId: Int, completion: @escaping (Result<UserDTO, Error>) -> Void) {
        print("🔄 NetworkManager: getUserProfile 호출됨 (userId: \(userId))")
        let urlString = "\(baseURL)/api/user?userid=\(userId)"
        guard let url = URL(string: urlString) else {
            print("❌ NetworkManager: 잘못된 URL: \(urlString)")
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = UserDefaults.standard.string(forKey: "userToken") {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("✅ NetworkManager: 토큰 헤더 추가됨: Bearer \(token.prefix(10))...")
        } else {
            print("⚠️ NetworkManager: 토큰이 없음, 인증 없이 요청")
        }
        
        print("🔄 NetworkManager: 요청 URL: \(urlString)")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ NetworkManager: 네트워크 오류: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            // HTTP 응답 로깅
            if let httpResponse = response as? HTTPURLResponse {
                print("ℹ️ NetworkManager: HTTP 상태 코드: \(httpResponse.statusCode)")
            }
            
            // 응답 데이터 출력
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("ℹ️ NetworkManager: 응답 데이터 (일부): \(responseString.prefix(200))")
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ NetworkManager: 올바르지 않은 HTTP 응답")
                completion(.failure(NetworkError.invalidResponse))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                print("❌ NetworkManager: 서버 오류 (코드: \(httpResponse.statusCode))")
                completion(.failure(NetworkError.serverError(httpResponse.statusCode)))
                return
            }
            
            guard let data = data else {
                print("❌ NetworkManager: 응답 데이터가 없음")
                completion(.failure(NetworkError.noData))
                return
            }
            
            do {
                // JSON 구조 체크 (디버깅용)
                if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("ℹ️ NetworkManager: JSON 키: \(jsonObject.keys.joined(separator: ", "))")
                    
                    // JSON 구조 체크
                    if jsonObject["userId"] == nil {
                        print("⚠️ NetworkManager: 응답에 userId 필드가 없습니다")
                    }
                    if jsonObject["email"] == nil {
                        print("⚠️ NetworkManager: 응답에 email 필드가 없습니다")
                    }
                    if jsonObject["nickname"] == nil {
                        print("⚠️ NetworkManager: 응답에 nickname 필드가 없습니다")
                    }
                }
                
                let decoder = JSONDecoder()
                let userDTO = try decoder.decode(UserDTO.self, from: data)
                
                // 성공한 경우 마지막 업데이트 시간 저장
                UserDefaults.standard.set(Date(), forKey: "lastProfileUpdate")
                
                print("✅ NetworkManager: UserDTO 디코딩 성공")
                print("   - userId: \(userDTO.userId)")
                print("   - nickname: \(userDTO.nickname)")
                print("   - email: \(userDTO.email)")
                completion(.success(userDTO))
            } catch {
                print("❌ NetworkManager: JSON 디코딩 오류: \(error)")
                
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, _):
                        print("   - 찾을 수 없는 키: \(key.stringValue)")
                    case .valueNotFound(let type, _):
                        print("   - 찾을 수 없는 값 타입: \(type)")
                    case .typeMismatch(let type, let context):
                        print("   - 타입 불일치: \(type)")
                        print("   - 경로: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                    case .dataCorrupted(let context):
                        print("   - 데이터 손상: \(context.debugDescription)")
                    @unknown default:
                        print("   - 알 수 없는 디코딩 오류")
                    }
                }
                
                // JSON 문자열 출력 (디버깅용)
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("ℹ️ NetworkManager: 전체 JSON 응답:")
                    print(jsonString)
                }
                
                completion(.failure(error))
            }
        }
        
        task.resume()
        print("🔄 NetworkManager: 네트워크 요청 시작됨")
    }
    
    // 회원가입
    func signUp(with dto: SignUpDTO, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/signup") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // form-urlencoded 형식으로 데이터 구성
        let parameters = [
            "email": dto.email,
            "password": dto.password,
            "nickname": dto.nickname
        ]
        
        let postData = parameters.map { key, value in
            "\(key)=\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        }.joined(separator: "&")
        
        // Debug
        print("Sending Data (form-urlencoded): \(postData)")
        
        request.httpBody = postData.data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // 응답 데이터 출력
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("Server response: \(responseString)")
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NetworkError.invalidResponse))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(NetworkError.serverError(httpResponse.statusCode)))
                return
            }
            
            guard let data = data,
                  let responseString = String(data: data, encoding: .utf8) else {
                completion(.failure(NetworkError.noData))
                return
            }
            completion(.success(responseString))
        }
        task.resume()
    }
    
    // 로그인
    func signIn(with dto: LoginDTO, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/signin") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "email", value: dto.email),
            URLQueryItem(name: "password", value: dto.password)
        ]
        
        let postData = components.percentEncodedQuery ?? ""
        // Login Debug
        print("Sending Data (form-urlencoded):\(postData)")
        
        request.httpBody = postData.data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // 응답 데이터 디버깅
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("Server Response: \(responseString)")
                
                // 응답에서 userId 추출 시도
                if let jsonData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let userId = jsonData["userId"] as? Int {
                    print("✅ 로그인 응답에서 userId 추출 성공: \(userId)")
                    UserDefaults.standard.set(userId, forKey: "userId")
                } else if let jsonData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let id = jsonData["id"] as? Int {
                    print("✅ 로그인 응답에서 id 추출 성공: \(id)")
                    UserDefaults.standard.set(id, forKey: "userId")
                } else {
                    print("⚠️ 응답에서 userId/id를 찾을 수 없음")
                }
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NetworkError.invalidResponse))
                return
            }
            
            //Authorization Header 에서 토큰 추출
            if let token = httpResponse.allHeaderFields["Authorization"] as? String {
                print("✅ 토큰 추출 성공: \(token.prefix(15))...")
                
                // 토큰에서 userId 추출 시도 (JWT 토큰인 경우)
                if token.starts(with: "Bearer ") {
                    let jwtToken = String(token.dropFirst(7))
                    if let userId = self.extractUserIdFromJWT(jwtToken) {
                        print("✅ JWT 토큰에서 userId 추출 성공: \(userId)")
                        UserDefaults.standard.set(userId, forKey: "userId")
                    }
                }
                
                // 토큰 저장
                UserDefaults.standard.set(token, forKey: "userToken")
                
                completion(.success(token))
                return
            }
            
            if httpResponse.statusCode == 401 {
                completion(.failure(NetworkError.invalidCredentials))
                return
            }
            completion(.failure(NetworkError.serverError(httpResponse.statusCode)))
        }
        task.resume()
    }
    
    private func extractUserIdFromJWT(_ token: String) -> Int? {
        let segments = token.components(separatedBy: ".")
        guard segments.count > 1 else { return nil }
        
        // base64url 디코딩
        var base64 = segments[1]
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        // 4의 배수로 패딩 추가
        while base64.count % 4 != 0 {
            base64.append("=")
        }
        
        guard let data = Data(base64Encoded: base64) else { return nil }
        
        do {
            if let payload = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                // JWT 토큰 내부의 다양한 userId 필드명 시도
                if let userId = payload["userId"] as? Int {
                    return userId
                } else if let userId = payload["sub"] as? Int {
                    return userId
                } else if let userId = payload["id"] as? Int {
                    return userId
                } else if let userIdString = payload["sub"] as? String, let userId = Int(userIdString) {
                    return userId
                } else if let userIdString = payload["userId"] as? String, let userId = Int(userIdString) {
                    return userId
                } else if let userIdString = payload["id"] as? String, let userId = Int(userIdString) {
                    return userId
                }
            }
        } catch {
            print("JWT 페이로드 파싱 오류: \(error)")
        }
        
        return nil
    }
    
    // 회원정보 수정
    func updateUserProfile(token: String, nickname: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/updateuser") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let parameters = [
            "nickname": nickname,
            "password": password
        ]
        
        let postData = parameters.map { key, value in
            "\(key)=\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        }.joined(separator: "&")
        
        print("Sending Data : \(postData)")
        
        request.httpBody = postData.data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            // Debug
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("Server Response: \(responseString)")
            }
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NetworkError.invalidResponse))
                return
            }
            
            // Debug
            print("Response Status Code: \(httpResponse.statusCode)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(NetworkError.serverError(httpResponse.statusCode)))
                return
            }
            
            completion(.success("프로필 변경 완료!"))
        }
        task.resume()
    }
    
    // 회원 탈퇴
    func deleteAccount(token: String, completion: @escaping (Result<String, Error>) -> Void) {
        let urlString = "\(baseURL)/api/deleteuser"
        print("🔄 회원 탈퇴 요청 URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ 잘못된 URL: \(urlString)")
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        // 토큰 형식 확인 및 정리
        let cleanToken = token.hasPrefix("Bearer ") ? token : "Bearer \(token)"
        print("🔄 Authorization 헤더: \(cleanToken.prefix(20))...")
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue(cleanToken, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 타임아웃 설정
        request.timeoutInterval = 30.0
        
        print("🔄 DELETE 요청 전송 시작")
        print("   - URL: \(url.absoluteString)")
        print("   - Method: DELETE")
        print("   - Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // 네트워크 오류 확인
            if let error = error {
                print("❌ 네트워크 오류: \(error.localizedDescription)")
                print("   - Error Code: \((error as NSError).code)")
                print("   - Error Domain: \((error as NSError).domain)")
                completion(.failure(error))
                return
            }
            
            // HTTP 응답 확인
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ HTTP 응답이 아님")
                completion(.failure(NetworkError.invalidResponse))
                return
            }
            
            print("ℹ️ HTTP 응답 정보:")
            print("   - 상태 코드: \(httpResponse.statusCode)")
            print("   - 응답 헤더:")
            httpResponse.allHeaderFields.forEach { key, value in
                print("     \(key): \(value)")
            }
            
            // 응답 본문 출력 (에러 분석용)
            if let data = data {
                print("ℹ️ 응답 데이터 크기: \(data.count) bytes")
                
                if let responseString = String(data: data, encoding: .utf8) {
                    print("ℹ️ 응답 본문:")
                    print("--- 응답 시작 ---")
                    print(responseString)
                    print("--- 응답 끝 ---")
                } else {
                    print("⚠️ 응답 본문을 UTF-8로 디코딩할 수 없음")
                }
            } else {
                print("⚠️ 응답 데이터가 없음")
            }
            
            // 상태 코드별 처리
            switch httpResponse.statusCode {
            case 200...299:
                print("✅ 회원 탈퇴 성공 (코드: \(httpResponse.statusCode))")
                let responseText = data.flatMap { String(data: $0, encoding: .utf8) } ?? "탈퇴 완료"
                completion(.success(responseText))
                
            case 400:
                print("❌ 잘못된 요청 (400)")
                completion(.failure(NetworkError.badRequest))
                
            case 401:
                print("❌ 인증 실패 (401) - 토큰이 유효하지 않음")
                completion(.failure(NetworkError.invalidCredentials))
                
            case 403:
                print("❌ 권한 없음 (403)")
                completion(.failure(NetworkError.authenticationRequired))
                
            case 404:
                print("❌ 리소스를 찾을 수 없음 (404)")
                completion(.failure(NetworkError.resourceNotFound))
                
            case 500...599:
                print("❌ 서버 내부 오류 (\(httpResponse.statusCode))")
                
                // 서버 오류 상세 정보 추출
                var errorDetails = "서버 오류가 발생했습니다 (코드: \(httpResponse.statusCode))"
                
                if let data = data, let errorMessage = String(data: data, encoding: .utf8), !errorMessage.isEmpty {
                    print("❌ 서버 오류 상세:")
                    print(errorMessage)
                    
                    // HTML 오류 페이지인지 확인
                    if errorMessage.contains("<html") || errorMessage.contains("<!DOCTYPE") {
                        errorDetails += "\n서버에서 HTML 오류 페이지를 반환했습니다."
                    } else {
                        errorDetails += "\n상세: \(errorMessage)"
                    }
                }
                
                completion(.failure(NetworkError.serverError(httpResponse.statusCode)))
                
            default:
                print("❌ 알 수 없는 HTTP 상태 코드: \(httpResponse.statusCode)")
                completion(.failure(NetworkError.unknownError(code: httpResponse.statusCode)))
            }
        }
        
        task.resume()
        print("🔄 회원 탈퇴 요청 전송 완료")
    }

    
    // 이메일로 사용자 ID 조회
    func getUserIdByEmail(email: String, completion: @escaping (Result<Int, Error>) -> Void) {
        print("🔄 이메일로 사용자 ID 조회 시작: \(email)")
        
        guard let url = URL(string: "\(baseURL)/api/getuser-by-email") else {
            print("❌ 잘못된 URL")
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        components?.queryItems = [URLQueryItem(name: "email", value: email)]
        
        guard let finalURL = components?.url else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var request = URLRequest(url: finalURL)
        request.httpMethod = "GET"
        
        if let token = UserDefaults.standard.string(forKey: "userToken") {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("✅ 토큰 설정됨: \(token.prefix(15))...")
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ 네트워크 오류: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ 올바르지 않은 HTTP 응답")
                completion(.failure(NetworkError.invalidResponse))
                return
            }
            
            print("ℹ️ HTTP 상태 코드: \(httpResponse.statusCode)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                print("❌ 서버 오류 (코드: \(httpResponse.statusCode))")
                completion(.failure(NetworkError.serverError(httpResponse.statusCode)))
                return
            }
            
            guard let data = data else {
                print("❌ 응답 데이터 없음")
                completion(.failure(NetworkError.noData))
                return
            }
            
            // 응답 데이터 확인
            if let responseString = String(data: data, encoding: .utf8) {
                print("ℹ️ 응답 데이터: \(responseString)")
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    // 다양한 필드명 시도
                    if let userId = json["userId"] as? Int {
                        print("✅ userId 필드 발견: \(userId)")
                        UserDefaults.standard.set(userId, forKey: "userId")
                        completion(.success(userId))
                        return
                    } else if let id = json["id"] as? Int {
                        print("✅ id 필드 발견: \(id)")
                        UserDefaults.standard.set(id, forKey: "userId")
                        completion(.success(id))
                        return
                    } else if let userIdString = json["userId"] as? String, let userId = Int(userIdString) {
                        print("✅ 문자열 userId 변환 성공: \(userId)")
                        UserDefaults.standard.set(userId, forKey: "userId")
                        completion(.success(userId))
                        return
                    } else if let idString = json["id"] as? String, let id = Int(idString) {
                        print("✅ 문자열 id 변환 성공: \(id)")
                        UserDefaults.standard.set(id, forKey: "userId")
                        completion(.success(id))
                        return
                    }
                    
                    print("❌ 응답에서 userId/id를 찾을 수 없음")
                    completion(.failure(NetworkError.noData))
                } else {
                    print("❌ JSON 파싱 실패")
                    completion(.failure(NetworkError.invalidResponse))
                }
            } catch {
                print("❌ JSON 디코딩 오류: \(error)")
                completion(.failure(error))
            }
        }
        
        task.resume()
        print("🔄 이메일로 사용자 ID 요청 전송됨")
    }
    
    // 찜 목록
    func getMyWishList(completion: @escaping (Result<[Wishlist], Error>) -> Void) {
        let urlString = "\(baseURL)/api/wishlist/getmywishlist"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "userToken") else {
            completion(.failure(NetworkError.authenticationRequired))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NetworkError.invalidResponse))
                return
            }
            
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                completion(.failure(NetworkError.authenticationRequired))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(NetworkError.serverError(httpResponse.statusCode)))
                return
            }
            
            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }
            
            do {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Wishlist Response: \(responseString)")
                }
                
                let decoder = JSONDecoder()
                let wishlistResponses = try decoder.decode([WishlistResponse].self, from: data)
                let wishlist = wishlistResponses.map { $0.toWishlist() }
                completion(.success(wishlist))
            } catch {
                print("Error decoding wishlist: \(error)")
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    // NetworkManager에서 위시리스트 관련 함수를 수정
    func addToWishlist(postId: Int, completion: @escaping (Result<Wishlist, Error>) -> Void) {
        let urlString = "\(baseURL)/api/wishlist/\(postId)"
        print("🔄 위시리스트 추가 요청: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ 잘못된 URL: \(urlString)")
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "userToken") else {
            print("❌ 토큰이 없음")
            completion(.failure(NetworkError.authenticationRequired))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("🔄 Authorization: Bearer \(token.prefix(15))...")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ 네트워크 오류: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("ℹ️ HTTP 상태 코드: \(httpResponse.statusCode)")
            }
            
            // 응답 데이터 출력
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("ℹ️ 응답 데이터: \(responseString)")
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ 올바르지 않은 HTTP 응답")
                completion(.failure(NetworkError.invalidResponse))
                return
            }
            
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                print("❌ 인증 오류 (코드: \(httpResponse.statusCode))")
                completion(.failure(NetworkError.authenticationRequired))
                return
            }
            
            // 500 서버 오류라도 성공으로 처리
            if httpResponse.statusCode == 500 {
                print("⚠️ 서버 오류 500 발생했지만 위시리스트 추가 성공으로 처리")
                // 최소한의 Wishlist 객체 생성
                let minimalWishlist = Wishlist(id: 0, userId: nil, postId: postId, post: nil)
                completion(.success(minimalWishlist))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                print("❌ 서버 오류 (코드: \(httpResponse.statusCode))")
                completion(.failure(NetworkError.serverError(httpResponse.statusCode)))
                return
            }
            
            guard let data = data else {
                print("❌ 응답 데이터가 없음")
                completion(.failure(NetworkError.noData))
                return
            }
            
            do {
                print("🔄 응답 디코딩 시도")
                
                // 디버깅: 실제 JSON 응답 출력
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Raw JSON response: \(jsonString)")
                }
                
                let decoder = JSONDecoder()
                
                // WishlistResponse 구조체로 먼저 디코딩 시도
                if let wishlistResponse = try? decoder.decode(WishlistResponse.self, from: data) {
                    print("✅ WishlistResponse 디코딩 성공")
                    let wishlist = wishlistResponse.toWishlist()
                    completion(.success(wishlist))
                }
                // 기존 Wishlist 구조체로 디코딩 시도
                else if let wishlist = try? decoder.decode(Wishlist.self, from: data) {
                    print("✅ Wishlist 디코딩 성공")
                    completion(.success(wishlist))
                }
                // 모두 실패한 경우 최소한의 Wishlist 객체 생성
                else {
                    print("경고: Wishlist 객체 디코딩 실패")
                    
                    // 최소한의 Wishlist 객체 생성
                    let minimalWishlist = Wishlist(id: 0, userId: nil, postId: postId, post: nil)
                    completion(.success(minimalWishlist))
                }
            } catch {
                print("❌ JSON 디코딩 오류: \(error)")
                completion(.failure(error))
            }
        }
        
        print("🔄 위시리스트 추가 요청 전송됨")
        task.resume()
    }
    
    // 게시물 수정하기
    func updatePost(postId: Int, postRequest: PostUpdateDTO, completion: @escaping (Result<Post, Error>) -> Void) {
        let urlString = "\(baseURL)/api/post/\(postId)"
        print("🔄 게시물 업데이트 요청 URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ 잘못된 URL: \(urlString)")
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        // 토큰 확인
        guard let token = UserDefaults.standard.string(forKey: "userToken") else {
            print("❌ 인증 토큰 없음")
            completion(.failure(NetworkError.authenticationRequired))
            return
        }
        
        // multipart/form-data 경계 문자열 생성
        let boundary = "Boundary-\(UUID().uuidString)"
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // 타임아웃 값 늘리기 (이미지 업로드 시간 고려)
        request.timeoutInterval = 60.0
        
        var body = Data()
        
        // 요청 파라미터 로깅
        print("📤 전송 파라미터:")
        print("   - title: \(postRequest.title)")
        print("   - content: \(postRequest.content)")
        print("   - price: \(postRequest.price)")
        print("   - place: \(postRequest.place)")
        print("   - status: \(postRequest.status)")
        print("   - imageUrls: \(postRequest.imageUrls)")
        
        // 필수 필드 추가 (PostDTO 필드들)
        addFormField(to: &body, boundary: boundary, name: "title", value: postRequest.title)
        addFormField(to: &body, boundary: boundary, name: "content", value: postRequest.content)
        addFormField(to: &body, boundary: boundary, name: "price", value: "\(postRequest.price)")
        addFormField(to: &body, boundary: boundary, name: "status", value: "\(postRequest.status)")
        
        // 위치 필드 추가
        addFormField(to: &body, boundary: boundary, name: "place", value: postRequest.place)
        
        // 중요: 기존 이미지 URL 보존하기
        if !postRequest.imageUrls.isEmpty {
            // 이미지 URL을 JSON 배열로 변환하여 한 번에 전송 (서버에서 지원하는 경우)
            let imageUrlsJson = try? JSONSerialization.data(withJSONObject: postRequest.imageUrls)
            if let imageUrlsJson = imageUrlsJson, let imageUrlsString = String(data: imageUrlsJson, encoding: .utf8) {
                addFormField(to: &body, boundary: boundary, name: "imageUrls", value: imageUrlsString)
                print("📤 이미지 URL JSON으로 전송: \(imageUrlsString)")
            } else {
                // 각 이미지 URL을 배열 형태로 전송
                for (index, imageUrl) in postRequest.imageUrls.enumerated() {
                    addFormField(to: &body, boundary: boundary, name: "imageUrls[\(index)]", value: imageUrl)
                }
                print("📤 기존 이미지 URL \(postRequest.imageUrls.count)개 포함")
            }
        }
        
        // 경계 종료
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ 네트워크 오류: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ 올바르지 않은 HTTP 응답")
                completion(.failure(NetworkError.invalidResponse))
                return
            }
            
            print("ℹ️ HTTP 상태 코드: \(httpResponse.statusCode)")
            
            // 응답 데이터 출력
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("ℹ️ 응답 본문:")
                print(responseString)
            }
            
            // 401/403 오류 처리
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                print("❌ 인증 오류 (코드: \(httpResponse.statusCode))")
                completion(.failure(NetworkError.authenticationRequired))
                return
            }
            
            // 상태 코드 확인
            guard (200...299).contains(httpResponse.statusCode) else {
                print("❌ 서버 오류 (코드: \(httpResponse.statusCode))")
                // 500 오류의 경우 응답 본문에서 추가 정보 확인 시도
                if httpResponse.statusCode == 500, let data = data, let errorMessage = String(data: data, encoding: .utf8) {
                    print("❌ 서버 오류 상세: \(errorMessage)")
                }
                completion(.failure(NetworkError.serverError(httpResponse.statusCode)))
                return
            }
            
            guard let data = data else {
                print("❌ 응답 데이터 없음")
                completion(.failure(NetworkError.noData))
                return
            }
            
            // JSON 파싱 및 디코딩
            do {
                let decoder = JSONDecoder()
                let post = try decoder.decode(Post.self, from: data)
                print("✅ 게시물 업데이트 성공 (ID: \(post.id))")
                completion(.success(post))
            } catch {
                print("❌ JSON 디코딩 오류: \(error)")
                completion(.failure(error))
            }
        }
        
        print("🔄 게시물 업데이트 요청 전송됨")
        task.resume()
    }
    
    
    
    // 게시물 삭제하기
    func deletePost(postId: Int, userId: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        let urlString = "\(baseURL)/api/post/\(postId)"
        print("🔄 게시물 삭제 요청: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ 잘못된 URL: \(urlString)")
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "userToken") else {
            print("❌ 인증 토큰 없음")
            completion(.failure(NetworkError.authenticationRequired))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // 요청 로깅
        print("🔄 DELETE 요청: \(url.absoluteString)")
        print("🔄 Authorization: Bearer \(token.prefix(15))...")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ 네트워크 오류: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ 올바르지 않은 HTTP 응답")
                completion(.failure(NetworkError.invalidResponse))
                return
            }
            
            print("ℹ️ HTTP 상태 코드: \(httpResponse.statusCode)")
            
            // 401/403 오류 처리
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                print("❌ 인증 오류 (코드: \(httpResponse.statusCode))")
                completion(.failure(NetworkError.authenticationRequired))
                return
            }
            
            // 상태 코드 확인
            guard (200...299).contains(httpResponse.statusCode) else {
                print("❌ 서버 오류 (코드: \(httpResponse.statusCode))")
                completion(.failure(NetworkError.serverError(httpResponse.statusCode)))
                return
            }
            
            print("✅ 게시물 삭제 성공 (ID: \(postId))")
            completion(.success(()))
        }
        
        task.resume()
    }
    
    // 찜 삭제
    func removeFromWishlist(postId: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        let urlString = "\(baseURL)/api/wishlist/\(postId)"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "userToken") else {
            completion(.failure(NetworkError.authenticationRequired))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NetworkError.invalidResponse))
                return
            }
            
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                completion(.failure(NetworkError.authenticationRequired))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(NetworkError.serverError(httpResponse.statusCode)))
                return
            }
            
            completion(.success(()))
        }
        
        task.resume()
    }
    
    // 기존 서버 API를 사용한 리뷰 생성
    func createReview(postId: Int, revieweeId: Int, requestDTO: ReviewRequestDTO, token: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "https://hanlumi.co.kr/api/posts/\(postId)/reviews/\(revieweeId)") else {
            print("❌ Invalid URL for createReview")
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        print("🔄 Creating review: POST \(url.absoluteString)")
        print("   - postId: \(postId), revieweeId: \(revieweeId)")
        print("   - rating: \(requestDTO.rating), comment: \(requestDTO.comment)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONEncoder().encode(requestDTO)
            request.httpBody = jsonData
            print("   - Request body: \(String(data: jsonData, encoding: .utf8) ?? "nil")")
        } catch {
            print("❌ JSON encoding error: \(error)")
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
                completion(.failure(NetworkError.networkError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid HTTP response")
                completion(.failure(NetworkError.invalidResponse))
                return
            }
            
            print("📡 Response status: \(httpResponse.statusCode)")
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("📡 Response body: \(responseString)")
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                print("✅ Review created successfully")
                completion(.success(()))
            case 401:
                print("❌ Unauthorized - invalid token")
                completion(.failure(NetworkError.invalidCredentials))
            case 400:
                print("❌ Bad request")
                completion(.failure(NetworkError.badRequest))
            default:
                print("❌ Server error: \(httpResponse.statusCode)")
                completion(.failure(NetworkError.serverError(httpResponse.statusCode)))
            }
        }.resume()
    }
    
    // 직접 리뷰 생성 (기존 API 활용, postId=0 사용)
    func createDirectReview(revieweeId: Int, requestDTO: ReviewRequestDTO, token: String, completion: @escaping (Result<Void, Error>) -> Void) {
        print("🔄 Creating direct review with postId=0")
        createReview(postId: 0, revieweeId: revieweeId, requestDTO: requestDTO, token: token, completion: completion)
    }
    
    // 받은 리뷰 목록 가져오기 (기존 API 사용)
    func getReceivedReviews(token: String, completion: @escaping (Result<[ReviewItem], Error>) -> Void) {
        guard let url = URL(string: "https://hanlumi.co.kr/api/reviews/received") else {
            print("❌ Invalid URL for getReceivedReviews")
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        print("🔄 Fetching received reviews: GET \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
                completion(.failure(NetworkError.networkError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid HTTP response")
                completion(.failure(NetworkError.invalidResponse))
                return
            }
            
            print("📡 Response status: \(httpResponse.statusCode)")
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("📡 Response body: \(responseString)")
            }
            
            switch httpResponse.statusCode {
            case 200:
                guard let data = data else {
                    print("❌ No data received")
                    completion(.failure(NetworkError.noData))
                    return
                }
                
                do {
                    let reviews = try JSONDecoder().decode([ReviewResponse].self, from: data)
                    print("✅ Decoded \(reviews.count) received reviews")
                    
                    let reviewItems = reviews.map { review in
                        ReviewItem(
                            reviewId: review.id,
                            rating: review.rating,
                            comment: review.comment,
                            reviewerNickname: review.reviewerNickname,
                            revieweeNickname: review.revieweeNickname,
                            createdAt: review.createdAt,
                            isReceived: true
                        )
                    }
                    completion(.success(reviewItems))
                } catch {
                    print("❌ JSON decoding error: \(error)")
                    if let decodingError = error as? DecodingError {
                        print("   Decoding error details: \(decodingError)")
                    }
                    completion(.failure(error))
                }
            case 401:
                print("❌ Unauthorized - invalid token")
                completion(.failure(NetworkError.invalidCredentials))
            default:
                print("❌ Server error: \(httpResponse.statusCode)")
                completion(.failure(NetworkError.serverError(httpResponse.statusCode)))
            }
        }.resume()
    }
    
    // 보낸 리뷰 목록 가져오기 (기존 API 사용)
    func getSentReviews(token: String, completion: @escaping (Result<[ReviewItem], Error>) -> Void) {
        guard let url = URL(string: "https://hanlumi.co.kr/api/reviews/sent") else {
            print("❌ Invalid URL for getSentReviews")
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        print("🔄 Fetching sent reviews: GET \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
                completion(.failure(NetworkError.networkError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid HTTP response")
                completion(.failure(NetworkError.invalidResponse))
                return
            }
            
            print("📡 Response status: \(httpResponse.statusCode)")
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("📡 Response body: \(responseString)")
            }
            
            switch httpResponse.statusCode {
            case 200:
                guard let data = data else {
                    print("❌ No data received")
                    completion(.failure(NetworkError.noData))
                    return
                }
                
                do {
                    let reviews = try JSONDecoder().decode([ReviewResponse].self, from: data)
                    print("✅ Decoded \(reviews.count) sent reviews")
                    
                    let reviewItems = reviews.map { review in
                        ReviewItem(
                            reviewId: review.id,
                            rating: review.rating,
                            comment: review.comment,
                            reviewerNickname: review.reviewerNickname,
                            revieweeNickname: review.revieweeNickname,
                            createdAt: review.createdAt,
                            isReceived: false
                        )
                    }
                    completion(.success(reviewItems))
                } catch {
                    print("❌ JSON decoding error: \(error)")
                    if let decodingError = error as? DecodingError {
                        print("   Decoding error details: \(decodingError)")
                    }
                    completion(.failure(error))
                }
            case 401:
                print("❌ Unauthorized - invalid token")
                completion(.failure(NetworkError.invalidCredentials))
            default:
                print("❌ Server error: \(httpResponse.statusCode)")
                completion(.failure(NetworkError.serverError(httpResponse.statusCode)))
            }
        }.resume()
    }
    
    
    // 채팅방 생성 또는 조회
    func createOrGetChatRoom(postId: Int, completion: @escaping (Result<ChatRoomResponse, NetworkError>) -> Void) {
        guard let token = UserDefaults.standard.string(forKey: "userToken") else {
            completion(.failure(.authenticationRequired))
            return
        }
        
        guard let url = URL(string: "https://hanlumi.co.kr/api/post/\(postId)/chatroom") else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = "{}".data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                guard let data = data else {
                    completion(.failure(.noData))
                    return
                }
                
                do {
                    let serverChatRoom = try JSONDecoder().decode(ServerChatRoom.self, from: data)
                    let chatRoomResponse = ChatRoomResponse(from: serverChatRoom)
                    completion(.success(chatRoomResponse))
                } catch {
                    if let jsonDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        let chatRoomResponse = ChatRoomResponse(from: jsonDict)
                        completion(.success(chatRoomResponse))
                    } else {
                        completion(.failure(.decodingError))
                    }
                }
                
            case 401:
                completion(.failure(.authenticationRequired))
            case 403:
                completion(.failure(.invalidCredentials))
            case 404:
                completion(.failure(.resourceNotFound))
            default:
                completion(.failure(.serverError(httpResponse.statusCode)))
            }
        }.resume()
    }
    
    // 채팅방 목록 조회
    func getChatRooms(completion: @escaping (Result<[ChatRoomResponse], NetworkError>) -> Void) {
        guard let token = UserDefaults.standard.string(forKey: "userToken") else {
            completion(.failure(.authenticationRequired))
            return
        }
        
        let userId = UserDefaults.standard.integer(forKey: "userId")
        let pathUserId = userId > 0 ? userId : 1
        
        guard let url = URL(string: "\(baseURL)/api/users/\(pathUserId)/chatrooms") else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                guard let data = data else {
                    completion(.failure(.noData))
                    return
                }
                
                if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [Any], jsonArray.isEmpty {
                    completion(.success([]))
                    return
                }
                
                do {
                    let serverChatRooms = try JSONDecoder().decode([ServerChatRoom].self, from: data)
                    let chatRoomResponses = serverChatRooms.map { ChatRoomResponse(from: $0) }
                    completion(.success(chatRoomResponses))
                } catch {
                    completion(.success([]))
                }
                
            case 401:
                completion(.failure(.authenticationRequired))
            case 403:
                completion(.failure(.invalidCredentials))
            case 404:
                completion(.success([]))
            default:
                completion(.failure(.serverError(httpResponse.statusCode)))
            }
        }.resume()
    }
    
    // 채팅방 메시지 목록 조회
    func getMessages(chatRoomId: Int, completion: @escaping (Result<[MessageResponse], NetworkError>) -> Void) {
        guard let token = UserDefaults.standard.string(forKey: "userToken") else {
            completion(.failure(.authenticationRequired))
            return
        }
        
        guard let url = URL(string: "\(baseURL)/api/chatroom/\(chatRoomId)/recent") else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                guard let data = data else {
                    completion(.failure(.noData))
                    return
                }
                
                if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [Any], jsonArray.isEmpty {
                    completion(.success([]))
                    return
                }
                
                do {
                    // 서버에서 ChatMessageDTO 배열 형태로 응답
                    if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                        let messageResponses = jsonArray.compactMap { json -> MessageResponse? in
                            return self.createMessageResponseFromJSON(json, chatRoomId: chatRoomId)
                        }
                        completion(.success(messageResponses))
                    } else {
                        let chatMessages = try JSONDecoder().decode([ChatMessageDTO].self, from: data)
                        let messageResponses = chatMessages.map { MessageResponse(from: $0, chatRoomId: chatRoomId) }
                        completion(.success(messageResponses))
                    }
                } catch {
                    completion(.success([]))
                }
                
            case 401:
                completion(.failure(.authenticationRequired))
            case 403:
                completion(.failure(.invalidCredentials))
            case 404:
                completion(.success([]))
            default:
                completion(.failure(.serverError(httpResponse.statusCode)))
            }
        }.resume()
    }
    
    // 메시지 전송
    func sendMessage(chatRoomId: Int, content: String, completion: @escaping (Result<MessageResponse, NetworkError>) -> Void) {
        guard let token = UserDefaults.standard.string(forKey: "userToken") else {
            completion(.failure(.authenticationRequired))
            return
        }
        
        // 서버 API 경로
        guard let url = URL(string: "\(baseURL)/api/chat/rooms/\(chatRoomId)/messages") else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // 요청 바디 생성
        let requestBody = SendMessageRequest(content: content)
        
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(requestBody)
        } catch {
            completion(.failure(.badRequest))
            return
        }
        
        // 네트워크 요청 실행
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                guard let data = data else {
                    completion(.failure(.noData))
                    return
                }
                
                do {
                    let message = try JSONDecoder().decode(MessageResponse.self, from: data)
                    completion(.success(message))
                } catch {
                    completion(.failure(.decodingError))
                }
                
            case 401:
                completion(.failure(.authenticationRequired))
                
            case 403:
                completion(.failure(.invalidCredentials))
                
            default:
                completion(.failure(.serverError(httpResponse.statusCode)))
            }
        }.resume()
    }
    
    // 웹소켓 연결
    func connectWebSocket(chatRoomId: Int, completion: @escaping (Result<Void, NetworkError>) -> Void) {
        // 같은 채팅방에 이미 연결되어 있다면 성공 처리
        if isConnected && currentChatRoomId == chatRoomId {
            print("ℹ️ 이미 같은 채팅방에 연결되어 있음")
            completion(.success(()))
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "userToken") else {
            completion(.failure(.authenticationRequired))
            return
        }
        
        // 다른 채팅방에 연결되어 있다면 연결 해제
        if isConnected && currentChatRoomId != chatRoomId {
            print("ℹ️ 다른 채팅방 연결 해제 후 새 연결")
            disconnectWebSocket()
        }
        
        guard let url = URL(string: "\(wsBaseURL)/ws/chat/\(chatRoomId)") else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        let bearerToken = token.hasPrefix("Bearer ") ? token : "Bearer \(token)"
        request.addValue(bearerToken, forHTTPHeaderField: "Authorization")
        
        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()
        
        updateWebSocketState(connected: false, chatRoomId: chatRoomId)
        
        // 연결 확인을 위한 핑 테스트
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.webSocketTask?.sendPing { [weak self] error in
                if let error = error {
                    print("❌ WebSocket 핑 실패: \(error)")
                    self?.updateWebSocketState(connected: false, chatRoomId: nil)
                    completion(.failure(.networkError(error)))
                    return
                }
                
                print("✅ WebSocket 연결 성공")
                self?.updateWebSocketState(connected: true, chatRoomId: chatRoomId)
                self?.receiveMessage()
                completion(.success(()))
            }
        }
    }
    
    // WebSocket 연결 해제
    func disconnectWebSocket() {
        print("🔄 WebSocket 연결 해제")
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        updateWebSocketState(connected: false, chatRoomId: nil)
    }
    
    
    // MARK: - 웹소켓으로 메시지 전송
    func sendWebSocketMessage(content: String) {
        guard let webSocketTask = webSocketTask, let chatRoomId = currentChatRoomId else {
            return
        }
        
        webSocketTask.send(.string(content)) { error in
            if let error = error {
                print("메시지 전송 실패 : \(error)")
            } else {
                print("메시지 전송 성공 : \(content)")
            }
        }
    }
    
    // 메시지 수신 메서드 수정 - 서버 응답 형식에 맞게
    private func receiveMessage() {
        guard let webSocketTask = webSocketTask, isConnected else {
            print("⚠️ WebSocket이 연결되지 않음")
            return
        }
                
        webSocketTask.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    print("📥 WebSocket 텍스트 메시지 수신: \(text.prefix(100))")
                    self.processReceivedMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        print("📥 WebSocket 데이터 메시지 수신: \(text.prefix(100))")
                        self.processReceivedMessage(text)
                    }
                @unknown default:
                    break
                }
                
                // 연결이 유지되고 있다면 계속 메시지 수신 대기
                if self.webSocketTask != nil && self.isConnected {
                    self.receiveMessage()
                }
                
            case .failure(let error):
                print("❌ WebSocket 메시지 수신 실패: \(error)")
                self.updateWebSocketState(connected: false, chatRoomId: nil)
                
                // 연결 취소 오류가 아닌 경우에만 재연결 시도
                let nsError = error as NSError
                if nsError.code != -999 { // NSURLErrorCancelled
                    print("🔄 3초 후 WebSocket 재연결 시도")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        if let chatRoomId = self.currentChatRoomId, !self.isConnected {
                            self.connectWebSocket(chatRoomId: chatRoomId) { result in
                                switch result {
                                case .success:
                                    print("✅ WebSocket 자동 재연결 성공")
                                case .failure(let error):
                                    print("❌ WebSocket 자동 재연결 실패: \(error)")
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func processReceivedMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else {
            print("⚠️ 메시지를 UTF-8로 변환 실패")
            return
        }
            
        print("📥 수신된 원본 메시지: \(text)")
        
        // 1. JSON 파싱으로 content 추출
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            print("✅ JSON 파싱 성공")
            
            if let contentString = json["content"] as? String,
               !contentString.isEmpty,
               let chatRoomId = currentChatRoomId {
                
                print("🎯 Content 추출 성공: \(contentString)")
                
                var finalContent = contentString
                
                // 이중 JSON 구조 처리
                if let contentData = contentString.data(using: .utf8),
                   let innerJson = try? JSONSerialization.jsonObject(with: contentData) as? [String: Any],
                   let actualContent = innerJson["content"] as? String {
                    finalContent = actualContent
                    print("📦 이중 JSON에서 실제 Content 추출: \(finalContent)")
                }
                
                // 발신자 ID 추출
                var senderId = 0
                if let directSenderId = json["senderId"] as? Int {
                    senderId = directSenderId
                } else if let sender = json["sender"] as? [String: Any],
                          let senderIdFromSender = sender["id"] as? Int {
                    senderId = senderIdFromSender
                }
                
                let messageId = json["id"] as? Int ?? Int.random(in: 1000...9999)
                
                let messageResponse = MessageResponse(
                    id: messageId,
                    chatRoomId: chatRoomId,
                    senderId: senderId,
                    content: finalContent,
                    createdAt: json["sentAt"] as? String ?? ISO8601DateFormatter().string(from: Date()),
                    isRead: true
                )
                
                print("✅ MessageResponse 생성 완료: \(messageResponse.content)")
                
                DispatchQueue.main.async {
                    self.messageHandler?(messageResponse)
                }
                return
            }
        }
        
        // 2. ChatMessageDTO 디코딩 시도
        do {
            let chatMessageDTO = try JSONDecoder().decode(ChatMessageDTO.self, from: data)
            if let chatRoomId = currentChatRoomId {
                let messageResponse = MessageResponse(from: chatMessageDTO, chatRoomId: chatRoomId)
                print("✅ ChatMessageDTO 디코딩 성공")
                
                DispatchQueue.main.async {
                    self.messageHandler?(messageResponse)
                }
                return
            }
        } catch {
            print("⚠️ ChatMessageDTO 디코딩 실패: \(error)")
        }
        
        // 3. 마지막 방법: 정규식으로 content 추출
        if let contentRange = text.range(of: "\"content\":\""),
           let endRange = text.range(of: "\"", range: contentRange.upperBound..<text.endIndex) {
            let content = String(text[contentRange.upperBound..<endRange.lowerBound])
            
            if !content.isEmpty {
                print("✅ 정규식으로 content 추출 성공: \(content)")
                
                let messageResponse = MessageResponse(
                    id: Int.random(in: 1000...9999),
                    chatRoomId: currentChatRoomId ?? 0,
                    senderId: 999,
                    content: content,
                    createdAt: ISO8601DateFormatter().string(from: Date()),
                    isRead: false
                )
                
                DispatchQueue.main.async {
                    self.messageHandler?(messageResponse)
                }
                return
            }
        }
        
        print("❌ 모든 메시지 파싱 방법 실패 - 메시지 무시")
    }
    
    // MARK: - 헬퍼 메서드들
    private func createMessageResponseFromJSON(_ json: [String: Any], chatRoomId: Int) -> MessageResponse? {
        let id = json["id"] as? Int ?? Int.random(in: 1000...9999)
                
        // content 필드만 추출하여 사용
        let content = json["content"] as? String ?? ""
        
        // 빈 content는 제외
        guard !content.isEmpty else { return nil }
        
        var senderId = 0
        if let directSenderId = json["senderId"] as? Int {
            senderId = directSenderId
        } else if let sender = json["sender"] as? [String: Any],
                  let senderIdFromSender = sender["id"] as? Int {
            senderId = senderIdFromSender
        }
        
        let createdAt = json["sentAt"] as? String ?? ISO8601DateFormatter().string(from: Date())
        
        return MessageResponse(
            id: id,
            chatRoomId: chatRoomId,
            senderId: senderId,
            content: content, // 여기서 content만 사용
            createdAt: createdAt,
            isRead: true
        )
    }
    
    private func parseMessageFromJSON(_ json: [String: Any], chatRoomId: Int) -> MessageResponse {
        let id = json["id"] as? Int ?? Int.random(in: 1000...9999)
        
        // content 필드만 추출하여 사용
        let content = json["content"] as? String ?? ""
        
        var senderId = 0
        if let directSenderId = json["senderId"] as? Int {
            senderId = directSenderId
        } else if let sender = json["sender"] as? [String: Any],
                  let senderIdFromSender = sender["id"] as? Int {
            senderId = senderIdFromSender
        }
        
        return MessageResponse(
            id: id,
            chatRoomId: chatRoomId,
            senderId: senderId,
            content: content, // 여기서 content만 사용
            createdAt: ISO8601DateFormatter().string(from: Date()),
            isRead: true
        )
    }
    
    private func createSimpleMessage(from text: String) {
        let messageResponse = MessageResponse(
            id: Int.random(in: 1000...9999),
            chatRoomId: currentChatRoomId ?? 0,
            senderId: 999,
            content: text,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            isRead: false
        )
        
        DispatchQueue.main.async {
            self.messageHandler?(messageResponse)
        }
    }
    
    private func updateWebSocketState(connected: Bool, chatRoomId: Int?) {
        isConnected = connected
                
        if let chatRoomId = chatRoomId {
            currentChatRoomId = chatRoomId
        } else if !connected {
            // 연결이 끊어진 경우에만 chatRoomId 초기화
            currentChatRoomId = nil
        }
        
        print("ℹ️ WebSocket 상태 업데이트: connected=\(connected), chatRoomId=\(currentChatRoomId ?? 0)")
    }
    
    // MARK: - 상태 확인
    func isWebSocketConnected() -> Bool {
        let connected = isConnected && webSocketTask != nil
        print("ℹ️ WebSocket 연결 상태 확인: \(connected)")
        return connected
    }
    
    func setWebSocketMessageHandler(_ handler: @escaping (MessageResponse) -> Void) {
        messageHandler = handler
    }
    
   
    // MARK: - NetworkError 확장
    enum NetworkError: LocalizedError {
        case invalidURL
        case noData
        case invalidResponse
        case serverError(Int)
        case invalidCredentials
        case authenticationRequired
        case badRequest
        case resourceNotFound
        case unknownError(code: Int)
        case networkError(Error)
        case decodingError
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "잘못된 URL입니다"
            case .noData:
                return "데이터를 받지 못했습니다"
            case .invalidResponse:
                return "서버로부터 올바르지 않은 응답을 받았습니다"
            case .serverError(let code):
                return "서버 오류가 발생했습니다 (코드: \(code))"
            case .invalidCredentials:
                return "이메일 또는 비밀번호가 일치하지 않습니다!"
            case .authenticationRequired:
                return "로그인이 필요합니다"
            case .badRequest:
                return "잘못된 요청입니다"
            case .resourceNotFound:
                return "요청한 리소스를 찾을 수 없습니다"
            case .unknownError(let code):
                return "알 수 없는 오류가 발생했습니다 (코드: \(code))"
            case .networkError(let error):
                return "네트워크 오류: \(error.localizedDescription)"
            case .decodingError:
                return "데이터 디코딩에 실패했습니다"
            }
        }
    }
}


