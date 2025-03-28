//
//  LoginViewController.swift
//  Market
//
//  Created by 장동혁 on 1/16/25.
//
import UIKit

// MARK : LoginViewController
class LoginViewController: UIViewController {
    // Market Title Label (추후 로고로 수정)
    private let marketLabel: UILabel = {
        let label = UILabel()
        label.text = "Market"
        label.font = .systemFont(ofSize: 35, weight: .bold)
        label.textAlignment = .center
        return label
    }()

    // Email 입력 필드
    private let emailTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Email"
        textField.borderStyle = .roundedRect
        textField.keyboardType = .emailAddress
        textField.autocapitalizationType = .none
        textField.returnKeyType = .next
        return textField
    }()
    
    // Password 입력 필드
    private let passwordTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Password"
        textField.borderStyle = .roundedRect
        textField.isSecureTextEntry = true
        textField.returnKeyType = .done
        textField.autocapitalizationType = .none
        return textField
    }()
    
    // Login Button
    private let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Login", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 5
        button.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // SignUp Button
    private let signupButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign Up", for: .normal)
        button.addTarget(self, action: #selector(navigateToSignup), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupNavigationBar()
        setupViews()
        setupTextFields()
    }
    
    private func setupNavigationBar() {
       // 백 버튼 제거
        navigationItem.hidesBackButton = true
    }
    
    private func setupTextFields() {
        emailTextField.delegate = self
        passwordTextField.delegate = self
    }
    
    private func setupViews() {
        // Market Label 추가
        view.addSubview(marketLabel)
        marketLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // StackView 설정
        let stackView = UIStackView(arrangedSubviews: [emailTextField, passwordTextField, loginButton, signupButton])
        stackView.axis = .vertical
        stackView.spacing = 15
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        
        stackView.setCustomSpacing(40, after: passwordTextField)
        
        // Auto Layout 설정
        NSLayoutConstraint.activate([
            // Market Label 제약조건
            marketLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            marketLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // StackView 제약 조건
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            emailTextField.heightAnchor.constraint(equalToConstant: 44),
            passwordTextField.heightAnchor.constraint(equalToConstant: 44),
            loginButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    @objc private func loginButtonTapped() {
        view.endEditing(true)
        
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(title: "입력 오류", message: "이메일과 비밀번호를 입력해주세요!")
            return
        }
        
        let loginDTO = LoginDTO(email: email, password: password)
        
        NetworkManager.shared.signIn(with: loginDTO) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let token):
                    // "Bearer " 제거하고 토큰만 저장
                    let pureToken = token.replacingOccurrences(of: "Bearer ", with: "")
                    UserDefaults.standard.set(pureToken, forKey: "userToken")
                    
                    UserDefaults.standard.set(email, forKey: "userEmail")
                    
                    // 토큰이 잘 저장되었는지 확인
                    print("Saved token: \(UserDefaults.standard.string(forKey: "userToken") ?? "no token")")
                    print("Saved email: \(UserDefaults.standard.string(forKey: "userEmail") ?? "no email")")
                    
                    let homeVC = HomeViewController()
                    self?.navigationController?.setViewControllers([homeVC], animated: true)
                case .failure(let error):
                    self?.showAlert(title: "로그인 실패!", message: error.localizedDescription)
                }
            }
        }
    }
    
    @objc private func navigateToSignup() {
        // SignUp Button Touched Method
        let signupVC = SignupViewController()
        navigationController?.pushViewController(signupVC, animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            loginButtonTapped()
        }
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}

