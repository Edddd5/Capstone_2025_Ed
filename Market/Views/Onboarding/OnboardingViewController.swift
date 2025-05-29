//
//  OnboardingViewController.swift
//  Market
//
//  Created by 장동혁 on 1/16/25.
//

import UIKit

// MARK : OnboardingViewController
class OnboardingViewController: UIViewController {
    
    // 배경 이미지 뷰
    private let backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "1242x2688")
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    // Onboarding 상황에서 Market 텍스트만 표시하기
    private let marketLabel: UILabel = {
       let label = UILabel()
        //label.text = "Market"
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textColor = .white // 보라색 배경에 맞춰 흰색으로 변경
        label.textAlignment = .center
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupViews()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.navigateToLogin()
        }
    }
    
    private func setupViews() {
        // 배경 이미지를 먼저 추가
        view.addSubview(backgroundImageView)
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Market 라벨을 그 위에 추가
        view.addSubview(marketLabel)
        marketLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // 배경 이미지를 전체 화면에 맞춤
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Market 라벨을 중앙에 배치
            marketLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            marketLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func navigateToLogin() {
        let loginVC = LoginViewController()
        navigationController?.pushViewController(loginVC, animated: true)
    }
}
