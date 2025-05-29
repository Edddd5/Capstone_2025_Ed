//
//  SignupViewController.swift
//  Market
//
//  Created by 장동혁 on 1/16/25.
//

import UIKit

// MARK : SignupController
class SignupViewController: UIViewController {
    // Sign Up Title
    private let signupLabel: UILabel = {
        let label = UILabel()
        label.text = "Sign Up"
        label.font = .systemFont(ofSize: 35, weight: .bold)
        label.textColor = UIColor(red: 75/255, green: 60/255, blue: 196/255, alpha: 1.0) // #4B3CC4 색상
        label.textAlignment = .center
        return label
    }()
    
    // 사용자 이름 입력 필드 생성
    private let usernameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Username" // 필드에 힌트 텍스트
        textField.borderStyle = .roundedRect // 필드 테두리 설정
        textField.autocapitalizationType = .none // 첫 글자 자동 대문자 수정 제한
        textField.returnKeyType = .next
        return textField
    }()
    
    // 이메일 입력 필드 생성
    private let emailTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Email" // 힌트 텍스트
        textField.borderStyle = .roundedRect // 테두리 설정
        textField.keyboardType = .emailAddress
        textField.autocapitalizationType = .none
        textField.returnKeyType = .next
        return textField
    }()
    
    // 비밀번호 입력 필드 생성
    private let passwordField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Password"
        textField.borderStyle = .roundedRect
        textField.isSecureTextEntry = true
        textField.autocapitalizationType = .none
        textField.returnKeyType = .next
        return textField
    }()
    
    // 비밀번호 확인 입력 필드 생성
    private let confirmPasswordField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Confirm Password"
        textField.borderStyle = .roundedRect
        textField.isSecureTextEntry = true
        textField.autocapitalizationType = .none
        textField.returnKeyType = .next
        return textField
    }()
    
    // 회원가입 버튼 생성
    private let signupButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign Up", for: .normal) // 버튼 텍스트 설정
        button.backgroundColor = UIColor(red: 75/255, green: 60/255, blue: 196/255, alpha: 1.0) // #4B3CC4 색상

        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 5
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white // 배경색 : 흰색
        setupViews() // 뷰 초기화 및 레이아웃 설정
        setupActions() // Button Action
        setupTextFields()
    }
    
    // UI Setup
    private func setupViews() {
        // signupLabel
        view.addSubview(signupLabel)
        signupLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 필드와 버튼을 포함하는 스택 뷰 생성
        let stackView = UIStackView(arrangedSubviews: [
            usernameTextField,
            emailTextField,
            passwordField,
            confirmPasswordField,
            signupButton
        ])
        
        stackView.axis = .vertical // 스택 방향을 세로로 설정
        stackView.spacing = 20 // 구성 요소 간 간격 설정
        view.addSubview(stackView) // 스택 뷰를 뷰에 추가
        
        stackView.setCustomSpacing(40, after: confirmPasswordField)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false // Auto Layout 활성화
        NSLayoutConstraint.activate([
            // SignUp Label 제약조건
            signupLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            signupLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor), // 스택 뷰를 화면 중앙에 배치 (가로)
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor), // 스택 뷰를 화면 중앙에 배치 (세로)
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20), // 스택 뷰 왼쪽 여백
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20), // 스택 뷰 오른쪽 여백
            
            signupButton.heightAnchor.constraint(equalToConstant: 44)
            
        ])
    }
    
    private func setupTextFields() {
        usernameTextField.delegate = self
        emailTextField.delegate = self
        passwordField.delegate = self
        confirmPasswordField.delegate = self
    }
    
    // Network Actions
    private func setupActions() {
        signupButton.addTarget(self, action: #selector(signupButtonTapped), for: .touchUpInside)
    }
    
    @objc private func signupButtonTapped() {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordField.text, !password.isEmpty,
              let confirmPassword = confirmPasswordField.text,
              let username = usernameTextField.text, !username.isEmpty else {
            showAlert(message: "모든 정보를 입력해주세요.")
            return
        }
        
        guard password == confirmPassword else {
            showAlert(message: "비밀번호가 일치하지 않습니다.")
            return
        }
        
        let signUpDTO = SignUpDTO(
            email: email,
            password: password,
            nickname: username
        )
        
        NetworkManager.shared.signUp(with: signUpDTO) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if response == "ok" {
                        self?.showAlert(message: "회원가입이 완료되었습니다!") {
                            self?.navigationController?.popViewController(animated: true)
                        }
                    } else {
                        self?.showAlert(message: "회원가입에 실패했습니다!")
                    }
                case .failure(let error):
                    self?.showAlert(message: error.localizedDescription)
                }
            }
        }
    }
    // Helper Methods
    private func showAlert(message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "확인", style: .default) { _ in
            completion?()
        }
        alert.addAction(okAction)
        present(alert, animated: true)
    }
}

extension SignupViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case usernameTextField:
            emailTextField.becomeFirstResponder()
        case emailTextField:
            passwordField.becomeFirstResponder()
        case passwordField:
            confirmPasswordField.becomeFirstResponder()
        case confirmPasswordField:
            textField.resignFirstResponder()  // 키보드 내리기
            signupButtonTapped()
        default:
            break
        }
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}
