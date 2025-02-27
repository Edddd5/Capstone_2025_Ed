//
//  OnboardingViewController.swift
//  Market
//
//  Created by 장동혁 on 1/16/25.
//

import UIKit

// MARK : OnboardingViewController
class OnboardingViewController: UIViewController {
    
    // Onboarding 상황에서 Market 텍스트만 표시하기
    private let marketLabel: UILabel = {
       let label = UILabel()
        label.text = "Market"
        label.font = .systemFont(ofSize: 32, weight: .bold)
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
        view.addSubview(marketLabel)
        marketLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            marketLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            marketLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func navigateToLogin() {
        let loginVC = LoginViewController()
        navigationController?.pushViewController(loginVC, animated: true)
    }
}
