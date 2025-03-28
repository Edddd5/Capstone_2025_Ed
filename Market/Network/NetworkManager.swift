//
//  NetworkManager.swift
//  Market
//
//  Created by 장동혁 on 2/6/25.
//

import Foundation

class NetworkManager {
    static let shared = NetworkManager()
    private let baseURL = "http://localhost:8080"
    
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
        guard let url = URL(string: "\(baseURL)/api/deleteuser") else {
            completion(.failure(NetworkError.invalidURL))
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
            
            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(NetworkError.serverError(httpResponse.statusCode)))
                return
            }
            completion(.success("회원 탈퇴 완료!"))
        }
        task.resume()
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
    func getMyWishList(completion: @escaping (Result<[Wishlist], Error > ) -> Void) {
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
                let wishlist = try decoder.decode([Wishlist].self, from: data)
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
                let decoder = JSONDecoder()
                let wishlist = try decoder.decode(Wishlist.self, from: data)
                print("✅ 위시리스트 추가 성공")
                completion(.success(wishlist))
            } catch {
                print("❌ JSON 디코딩 오류: \(error)")
                completion(.failure(error))
            }
        }
        
        print("🔄 위시리스트 추가 요청 전송됨")
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
    
    enum NetworkError: LocalizedError {
        case invalidURL
        case noData
        case invalidResponse
        case serverError(Int)
        case invalidCredentials
        case authenticationRequired
        
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
            }
        }
    }
}
