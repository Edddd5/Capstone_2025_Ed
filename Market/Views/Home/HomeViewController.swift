//
//  HomeViewController.swift
//  Market
//
//  Created by 장동혁 on 1/20/25.
//

import UIKit

class HomeViewController: UIViewController {
    // 임시 Home Title Label (추후 디자인 수정)
    private let homeLabel: UILabel = {
       let label = UILabel()
       label.text = "Home"
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
        // 백 버튼 제거
        navigationItem.hidesBackButton = true
    }
    
    private func setupViews() {
        // Home Label 추가
        view.addSubview(homeLabel)
        homeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Auto Layout 설정
        NSLayoutConstraint.activate([
            homeLabel.topAnchor.constraint(equalTo:
                view.safeAreaLayoutGuide.topAnchor, constant: 100),
            homeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func setupTabBar() {
        // TabBar View
        view.addSubview(customTabBar)
        customTabBar.translatesAutoresizingMaskIntoConstraints = false
        
        // TabBar Layout 설정
        NSLayoutConstraint.activate([
            // TabBarView 제약
            customTabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customTabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customTabBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            customTabBar.heightAnchor.constraint(equalToConstant: 90)
        ])
        
        customTabBar.updateButtonColors(customTabBar.homeButton)
        
        customTabBar.didTapButton = { [weak self] button in
            switch button {
            case self?.customTabBar.homeButton:
                print("Home")
            case self?.customTabBar.chatButton:
                let chatVC = ChatViewController()
                self?.navigationController?.pushViewController(chatVC, animated: false)
            case self?.customTabBar.profileButton:
                let profileVC = ProfileViewController()
                self?.navigationController?.pushViewController(profileVC, animated: false)
            default:
                break
            }
        }
    }
}

// UIButton Extension for centering image and Title
extension UIButton {
    func centerImageAndButton(spacing: CGFloat = 6.0) {
        self.contentHorizontalAlignment = .center
        self.contentVerticalAlignment = .center
        
        let imageWidth = self.imageView?.image?.size.width ?? 0
        let imageHeight = self.imageView?.image?.size.height ?? 0
        
        let labelWidth = self.titleLabel?.intrinsicContentSize.width ?? 0
        let labelHeight = self.titleLabel?.intrinsicContentSize.height ?? 0
        
        self.imageEdgeInsets = UIEdgeInsets(
            top: -labelHeight - spacing/2,
            left: 0,
            bottom: 0,
            right: -labelWidth
        )
        
        self.titleEdgeInsets = UIEdgeInsets(
            top: 0,
            left: -imageWidth,
            bottom: -imageHeight - spacing/2,
            right: 0
        )
    }
}


