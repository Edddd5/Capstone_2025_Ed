//
//  UIImageView.swift
//  Market
//
//  Created on 5/29/25.
//

import UIKit

extension UIImageView {
    
    /// 프로필 이미지를 서버에서 로드하는 메서드
    /// - Parameter urlString: 프로필 이미지 파일명 (예: "profile_123.jpg")
    func loadProfileImage(from urlString: String?) {
        guard let urlString = urlString,
              !urlString.isEmpty,
              let url = URL(string: "https://hanlumi.co.kr/images/profile/\(urlString)") else {
            // 기본 프로필 이미지 설정
            self.image = UIImage(systemName: "person.circle.fill")
            self.tintColor = .systemGray4
            return
        }
        
        // 로딩 중 기본 이미지 표시
        self.image = UIImage(systemName: "person.circle")
        self.tintColor = .systemGray5
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("❌ 프로필 이미지 로드 오류: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.image = UIImage(systemName: "person.circle.fill")
                    self?.tintColor = .systemGray4
                }
                return
            }
            
            // HTTP 응답 코드 확인
            if let httpResponse = response as? HTTPURLResponse {
                guard (200...299).contains(httpResponse.statusCode) else {
                    print("❌ 프로필 이미지 로드 실패: HTTP \(httpResponse.statusCode)")
                    DispatchQueue.main.async {
                        self?.image = UIImage(systemName: "person.circle.fill")
                        self?.tintColor = .systemGray4
                    }
                    return
                }
            }
            
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self?.image = image
                    self?.tintColor = .clear
                }
            } else {
                DispatchQueue.main.async {
                    self?.image = UIImage(systemName: "person.circle.fill")
                    self?.tintColor = .systemGray4
                }
            }
        }.resume()
    }
    
    /// 일반 이미지를 URL에서 로드하는 메서드 (기존 loadImage 개선)
    /// - Parameter url: 이미지 URL
    func loadImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("❌ 이미지 로드 오류: \(error.localizedDescription)")
                return
            }
            
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self?.image = image
                }
            }
        }.resume()
    }
}
