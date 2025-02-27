//
//  ChatViewController.swift
//  Market
//
//  Created by 장동혁 on 1/30/25.
//

import UIKit

class ChatViewController: UIViewController {
    // 임시 Chat Title Label (추후 디자인 수정)
    private let profileLabel: UILabel = {
        let label = UILabel()
        label.text = "Chat"
        label.font = .systemFont(ofSize: 35, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private let customTabBar = CustomTabBar()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupNavigationBar()
        setupViews()
        setupTabBar()
    }
    
    private func setupNavigationBar() {
        navigationItem.hidesBackButton = true
    }
    
    private func setupViews() {
        view.addSubview(profileLabel)
        profileLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            profileLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            profileLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func setupTabBar() {
        view.addSubview(customTabBar)
        customTabBar.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            customTabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customTabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customTabBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            customTabBar.heightAnchor.constraint(equalToConstant: 90)
        ])
        
        // 채팅 화면에서는 프로필 버튼이 선택된 상태로 표시
        customTabBar.updateButtonColors(customTabBar.chatButton)
        
        customTabBar.didTapButton = { [weak self] button in
            switch button {
            case self?.customTabBar.homeButton:
                // 홈 버튼을 누르면 루트 뷰 컨드롤러(홈)로 이동
                let homeVC = HomeViewController()
                self?.navigationController?.pushViewController(homeVC, animated: false)
            case self?.customTabBar.chatButton:
                print("Already in Chat")
            case self?.customTabBar.profileButton:
                // 프로필 버튼을 누르면 프로필 화면으로 이동
                let profileVC = ProfileViewController()
                self?.navigationController?.pushViewController(profileVC, animated: false)
            default:
                break
            }
        }
    }
}
