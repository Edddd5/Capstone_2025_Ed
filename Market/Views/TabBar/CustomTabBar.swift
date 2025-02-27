//
//  CustomTabBar.swift
//  Market
//
//  Created by 장동혁 on 1/30/25.
//

// CustomTabBar.swift
import UIKit

class CustomTabBar: UIView {
    // 탭 버튼을 담는 컨테이너
    private let tabBarView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.borderWidth = 0.5
        view.layer.borderColor = UIColor.lightGray.cgColor
        return view
    }()
    
    // Home 버튼
    lazy var homeButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 24)
        button.setImage(UIImage(systemName: "house.fill", withConfiguration: config), for: .normal)
        button.tintColor = .systemBlue
        button.setTitle("홈", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 13)
        button.centerImageAndButton(spacing: 8)
        return button
    }()
    
    // Chat 버튼
    lazy var chatButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 24)
        button.setImage(UIImage(systemName: "message", withConfiguration: config), for: .normal)
        button.tintColor = .gray
        button.setTitle("채팅", for: .normal)
        button.setTitleColor(.gray, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 13)
        button.centerImageAndButton(spacing: 8)
        return button
    }()
    
    // Profile 버튼
    lazy var profileButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 24)
        button.setImage(UIImage(systemName: "person", withConfiguration: config), for: .normal)
        button.tintColor = .gray
        button.setTitle("내 정보", for: .normal)
        button.setTitleColor(.gray, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 13)
        button.centerImageAndButton(spacing: 8)
        return button
    }()
    
    var didTapButton: ((UIButton) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupTabBar()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupTabBar() {
        addSubview(tabBarView)
        tabBarView.translatesAutoresizingMaskIntoConstraints = false
        
        tabBarView.addSubview(homeButton)
        tabBarView.addSubview(chatButton)
        tabBarView.addSubview(profileButton)
        
        homeButton.translatesAutoresizingMaskIntoConstraints = false
        chatButton.translatesAutoresizingMaskIntoConstraints = false
        profileButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tabBarView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tabBarView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tabBarView.bottomAnchor.constraint(equalTo: bottomAnchor),
            tabBarView.heightAnchor.constraint(equalToConstant: 90),
            
            homeButton.leadingAnchor.constraint(equalTo: tabBarView.leadingAnchor),
            homeButton.widthAnchor.constraint(equalTo: tabBarView.widthAnchor, multiplier: 0.33),
            homeButton.topAnchor.constraint(equalTo: tabBarView.topAnchor, constant: 20),
            
            chatButton.centerXAnchor.constraint(equalTo: tabBarView.centerXAnchor),
            chatButton.widthAnchor.constraint(equalTo: tabBarView.widthAnchor, multiplier: 0.33),
            chatButton.topAnchor.constraint(equalTo: tabBarView.topAnchor, constant: 20),
            
            profileButton.trailingAnchor.constraint(equalTo: tabBarView.trailingAnchor),
            profileButton.widthAnchor.constraint(equalTo: tabBarView.widthAnchor, multiplier: 0.33),
            profileButton.topAnchor.constraint(equalTo: tabBarView.topAnchor, constant: 20)
        ])
    }
    
    private func setupActions() {
        homeButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        chatButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        profileButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }
    
    @objc private func buttonTapped(_ sender: UIButton) {
        updateButtonColors(sender)
        didTapButton?(sender)
    }
    
    func updateButtonColors(_ selectedButton: UIButton) {
        [homeButton, chatButton, profileButton].forEach { button in
            button.tintColor = .gray
            button.setTitleColor(.gray, for: .normal)
        }
        
        selectedButton.tintColor = .systemBlue
        selectedButton.setTitleColor(.systemBlue, for: .normal)
    }
}
