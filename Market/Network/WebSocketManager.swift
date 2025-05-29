// WebSocketManager.swift 수정
import Foundation

class WebSocketManager {
    static let shared = WebSocketManager()
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession?
    private var isConnected = false
    private var reconnectTimer: Timer?
    private var currentChatRoomId: Int?
    private let baseWSURL = "wss://hanlumi.co.kr"
    
    // 메시지 수신 콜백
    var onMessageReceived: ((MessageResponse) -> Void)?
    
    // 연결 상태 변경 콜백
    var onConnectionStateChanged: ((Bool) -> Void)?
    
    private init() {
        session = URLSession(configuration: .default)
    }
    
    // MARK: - Connection Management
    
    func connect(token: String, chatRoomId: Int) {
        // 이미 연결 중인지 확인
        if isConnected && currentChatRoomId == chatRoomId {
            print("🔧 WebSocket already connected to chat room \(chatRoomId)")
            return
        }
        
        // 기존 연결 종료
        disconnect()
        
        // 새 연결 준비
        currentChatRoomId = chatRoomId
        
        // WebSocket URL 생성 - 서버 코드 확인 후 정확한.
        // URL 패턴 사용 (ChatRoomSocketHandler or WebSocketConfig)
        guard let url = URL(string: "\(baseWSURL)/ws/chat/\(chatRoomId)") else {
            print("❌ Invalid WebSocket URL")
            return
        }
        
        print("🔄 Connecting to WebSocket: \(url.absoluteString)")
        
        // 웹소켓 요청 생성
        var request = URLRequest(url: url)
        request.timeoutInterval = 10 // 타임아웃 증가
        
        // Authorization 헤더 추가 - 서버에서 인증을 처리할 수 있도록
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("✅ Token added to WebSocket request")
        }
        
        // Authorization 헤더 설정 - 로깅 추가
        let bearerToken = token.hasPrefix("Bearer ") ? token : "Bearer \(token)"
        request.setValue(bearerToken, forHTTPHeaderField: "Authorization")
        
        // 헤더 확인 로깅 추가
        print("\n📋 WebSocket 요청 헤더:")
        print("   Authorization: \(bearerToken.prefix(30))...[총(bearerToken.count)자]")
        print("   URL: \(url.absoluteString)")
        
        // 웹소켓 태스크 생성 및 시작
        webSocketTask = session?.webSocketTask(with: request)
        webSocketTask?.resume()
        
        // 연결 확인을 위한 핑 전송
        sendPing { [weak self] success in
            guard let self = self else { return }
            
            if success {
                print("✅ WebSocket connected successfully")
                self.isConnected = true
                self.onConnectionStateChanged?(true)
                
                // 메시지 수신 시작
                self.receiveMessage()
                
                // 주기적 핑 시작
                self.schedulePing()
            } else {
                print("❌ WebSocket connection failed")
                self.isConnected = false
                self.onConnectionStateChanged?(false)
                
                // 재연결 시도
                self.startReconnectTimer()
            }
        }
    }
    
    func disconnect() {
        print("🔄 Disconnecting WebSocket")
        
        // 타이머 정지
        stopReconnectTimer()
        
        // 연결 종료
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        
        isConnected = false
        currentChatRoomId = nil
        onConnectionStateChanged?(false)
        
        print("✅ WebSocket disconnected")
    }
    
    // MARK: - Message Sending
    
    func sendMessage(content: String, completion: @escaping (Bool) -> Void) {
        guard isConnected, let webSocketTask = webSocketTask, let chatRoomId = currentChatRoomId else {
            print("❌ WebSocket not connected")
            completion(false)
            return
        }
        
        // ChatMessageDTO 형식에 맞게 JSON 구성
        let messageDict: [String: Any] = [
            "content": content,
            "chatRoomId": chatRoomId
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: messageDict)
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                print("❌ Failed to convert message to JSON string")
                completion(false)
                return
            }
            
            print("🔄 Sending WebSocket message: \(jsonString)")
            
            let message = URLSessionWebSocketTask.Message.string(jsonString)
            webSocketTask.send(message) { error in
                if let error = error {
                    print("❌ Error sending message: \(error.localizedDescription)")
                    
                    // 연결 문제일 경우 재연결 시도
                    if (error as NSError).domain == NSPOSIXErrorDomain && (error as NSError).code == 57 {
                        print("🔄 Socket not connected, attempting to reconnect...")
                        self.isConnected = false
                        self.onConnectionStateChanged?(false)
                        self.startReconnectTimer()
                    }
                    
                    completion(false)
                    return
                }
                
                print("✅ Message sent successfully")
                completion(true)
            }
        } catch {
            print("❌ JSON serialization error: \(error.localizedDescription)")
            completion(false)
        }
    }
    
    // HTTP API로 메시지 전송 (WebSocket 실패 시 대체 방법)
    func sendMessageViaHTTP(chatRoomId: Int, content: String, completion: @escaping (Bool, String?) -> Void) {
        NetworkManager.shared.sendMessage(chatRoomId: chatRoomId, content: content) { result in
            switch result {
            case .success(_):
                print("✅ Message sent via HTTP API")
                completion(true, nil)
            case .failure(let error):
                print("❌ Failed to send message via HTTP: \(error.localizedDescription)")
                completion(false, error.localizedDescription)
            }
        }
    }
    
    // MARK: - Message Receiving
    
    private func receiveMessage() {
        guard let webSocketTask = webSocketTask, isConnected else { return }
        
        webSocketTask.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    print("📥 Received WebSocket text: \(text)")
                    self.handleTextMessage(text)
                case .data(let data):
                    print("📥 Received WebSocket binary data: \(data.count) bytes")
                    if let text = String(data: data, encoding: .utf8) {
                        self.handleTextMessage(text)
                    }
                @unknown default:
                    print("⚠️ Unknown WebSocket message type")
                }
                
                // 다음 메시지 수신 대기
                if self.isConnected {
                    self.receiveMessage()
                }
                
            case .failure(let error):
                print("❌ WebSocket receive error: \(error.localizedDescription)")
                
                // 연결이 끊어진 경우
                self.isConnected = false
                self.onConnectionStateChanged?(false)
                
                // 재연결 시도
                self.startReconnectTimer()
            }
        }
    }
    
    // MARK: - Ping/Pong
    
    private func sendPing(completion: ((Bool) -> Void)? = nil) {
        webSocketTask?.sendPing { [weak self] error in
            if let error = error {
                print("❌ Ping error: \(error.localizedDescription)")
                completion?(false)
                return
            }
            
            print("✅ Ping successful")
            completion?(true)
        }
    }
    
    private func schedulePing() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
            guard let self = self, self.isConnected else { return }
            
            self.sendPing { success in
                if success && self.isConnected {
                    // 다음 핑 예약
                    self.schedulePing()
                }
            }
        }
    }
    
    // MARK: - Reconnection Logic
    
    private func startReconnectTimer() {
        stopReconnectTimer()
        
        print("🔄 Starting reconnect timer...")
        
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self = self,
                  let chatRoomId = self.currentChatRoomId,
                  let token = UserDefaults.standard.string(forKey: "userToken") else {
                self?.stopReconnectTimer()
                return
            }
            
            print("🔄 Attempting to reconnect WebSocket...")
            self.connect(token: token, chatRoomId: chatRoomId)
        }
    }
    
    private func stopReconnectTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
    
    // MARK: - Message Handling
    
    private func handleTextMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else {
            print("❌ Could not convert WebSocket text to data")
            return
        }
        
        do {
            // JSON 구조 확인
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("📊 WebSocket JSON structure: \(json.keys.joined(separator: ", "))")
            }
            
            // 서버 응답을 ChatMessageDTO로 디코딩 시도
            if let chatMessageDTO = try? JSONDecoder().decode(ChatMessageDTO.self, from: data) {
                print("✅ Successfully decoded as ChatMessageDTO")
                
                // MessageResponse로 변환
                if let chatRoomId = self.currentChatRoomId {
                    let messageResponse = MessageResponse(
                        from: chatMessageDTO,
                        chatRoomId: chatRoomId
                    )
                    
                    // 콜백 호출
                    DispatchQueue.main.async {
                        self.onMessageReceived?(messageResponse)
                    }
                    return
                }
            }
            
            // ChatMessageDTO 디코딩 실패 시 MessageResponse로 직접 디코딩 시도
            if let messageResponse = try? JSONDecoder().decode(MessageResponse.self, from: data) {
                print("✅ Successfully decoded as MessageResponse")
                
                // 콜백 호출
                DispatchQueue.main.async {
                    self.onMessageReceived?(messageResponse)
                }
                return
            }
            
            // 모든 디코딩 실패 시 fallback 처리
            print("⚠️ Could not decode WebSocket message, using fallback")
            createFallbackMessage(from: text)
            
        } catch {
            print("❌ Failed to process WebSocket message: \(error)")
            createFallbackMessage(from: text)
        }
    }
    
    private func createFallbackMessage(from text: String) {
        // 임시 메시지 생성
        let now = Date()
        let userId = UserDefaults.standard.integer(forKey: "userId")
        
        // 수신된 메시지에서 임의로 MessageResponse 객체 생성
        let mockResponse = MessageResponse(
            id: Int.random(in: 1000...9999),
            chatRoomId: currentChatRoomId ?? 0,
            senderId: userId == 0 ? 999 : userId, // 다른 사용자로 가정
            content: text,
            createdAt: ISO8601DateFormatter().string(from: now),
            isRead: false
        )
        
        // 콜백 호출
        DispatchQueue.main.async {
            self.onMessageReceived?(mockResponse)
        }
    }
    
    // MARK: - Helper Methods
    
    func isConnectedToChatRoom(_ chatRoomId: Int) -> Bool {
        return isConnected && currentChatRoomId == chatRoomId
    }
    
    func getCurrentChatRoomId() -> Int? {
        return currentChatRoomId
    }
}
