//
//  SignupViewController.swift
//  hima
//
//  Created by 二本松秀樹 on 2021/02/25.
//

import UIKit
import Firebase
import PKHUD

class SignupViewController: UIViewController {
    @IBOutlet private weak var nameTextField: UITextField!
    @IBOutlet private weak var emailTextField: UITextField!
    @IBOutlet private weak var passwordTextField: UITextField!
    
    @IBOutlet var submitButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    private func showError(_ errorOrNil: Error?) {
        // エラーがなければ何もしない
        guard let error = errorOrNil else { return }
        
        let message = errorMessage(of: error)
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    private func errorMessage(of error: Error) -> String {
        var message = "エラーが発生しました"
        guard let errcd = AuthErrorCode(rawValue: (error as NSError).code) else {
            return message
        }
        
        switch errcd {
        case .networkError: message = "ネットワークに接続できません"
        case .userNotFound: message = "ユーザが見つかりません"
        case .invalidEmail: message = "不正なメールアドレスです"
        case .emailAlreadyInUse: message = "このメールアドレスは既に使われています"
        case .wrongPassword: message = "入力した認証情報でサインインできません"
        case .userDisabled: message = "このアカウントは無効です"
        case .weakPassword: message = "パスワードが脆弱すぎます"
        default: break
        }
        return message
    }
    
    @IBAction private func didTapSignUpButton() {
        let email = emailTextField.text ?? ""
        let password = passwordTextField.text ?? ""
        let name = nameTextField.text ?? ""
        
        print("enter Signup")
        HUD.show(.progress)
        self.view.endEditing(true)
        self.signUp(email: email, password: password, name: name)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    private func signUp(email: String, password: String, name: String) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self]result, error in
            guard let self = self else {return}
            
            if let user = result?.user { // userのアンラップ処理
                print("enter updateDisplayName")
                self.updateDisplayName(name, of: user)
                return
            }
            HUD.hide()
            self.showError(error)
        }
    }
    
    private func updateDisplayName(_ name: String, of user: User) {
        let request = user.createProfileChangeRequest()
        request.displayName = name
        request.commitChanges{ [weak self]error in
            guard let self = self else { return }
            if error == nil {
                print("enter EmailVerification")
                self.sendEmailVerification(to: user)
                return
            }
            HUD.hide()
            self.showError(error)
        }
    }
    
    private func sendEmailVerification(to user: User) {
        user.sendEmailVerification { [weak self]error in
            guard let self = self else { return }
            if error == nil {
                HUD.flash(.success, onView: self.view, delay: 1.0) { (_) in
                    // 仮登録完了画面へ遷移する処理
                    print("enter showSignupCompleted")
                    self.showSignupCompleted()
                    return
                }
            }
            self.showError(error)
        }
    }
    
    private func showSignupCompleted() {
        // 仮登録完了画面へ
        let navigationController = self.presentingViewController as! UINavigationController
        let signinView = navigationController.topViewController as! SigninViewController
        signinView.emailTextField.text = self.emailTextField.text
        signinView.passwordTextField.text = self.passwordTextField.text
        performSegue(withIdentifier: "toSignupCompletedView", sender: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}
