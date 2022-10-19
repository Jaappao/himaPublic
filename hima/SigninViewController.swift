//
//  SigninViewController.swift
//  hima
//
//  Created by 二本松秀樹 on 2021/02/25.
//

import UIKit
import Firebase
import PKHUD

class SigninViewController: UIViewController {
    
    @IBOutlet public weak var emailTextField: UITextField!
    @IBOutlet public weak var passwordTextField: UITextField!
    
    @IBOutlet var loginButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let user = Auth.auth().currentUser {
            if user.isEmailVerified {
                // メール認証済の人はすぐにホーム画面を表示する
                self.showHomeView()
            } else {
                // サインアウトしてログイン画面を表示する
                print("[viewDidLoad] email not Authrorized")
                do{
                    try Auth.auth().signOut()
                } catch let error {
                    print("Error signing out \(error)")
                }
            }
            return
        } else {
            emailTextField.text = ""
            passwordTextField.text = ""
            self.view.endEditing(true)
            return
        }
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        emailTextField.text = ""
        passwordTextField.text = ""
        self.view.endEditing(true)
    }

    
    @IBAction private func didTapSignInButton() {
        let email = emailTextField.text ?? ""
        let password = passwordTextField.text ?? ""
        
        self.view.endEditing(true)
        HUD.show(.progress)
        self.signIn(email: email, password: password)
    }
    
    func signIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self]result, error in
            guard let self = self else { return }
            if let user = result?.user {
                print("[Signin] \(user.uid): \(user.displayName)")
                
                if user.isEmailVerified {
                    // Home画面へ遷移
                    HUD.flash(.success, onView: self.view, delay:0.5) { (_) in
                        self.showHomeView()
                    }
                    return
                } else {
                    user.sendEmailVerification { (error) in
                        if let error = error {
                            print("Error sending Email \(error)")
                            return
                        } else {
                            do{
                                try Auth.auth().signOut()
                            } catch let error {
                                print("Error signing out \(error)")
                            }
                            
                            let alert = UIAlertController(title: "メールアドレスの確認が済んでいません", message: "ログインに使用しているメールアドレスのリンクを確認してください", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                        }
                    }
                }
            }
            HUD.hide(animated: true)
            self.showErrorIfNeeded(error)
        }
    }
    
    private func showErrorIfNeeded(_ errorOrNil: Error?) {
        // エラーがなければ何もしません
        guard let error = errorOrNil else { return }
        
        let message = errorMessage(of: error) // エラーメッセージを取得
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
        case .tooManyRequests: message = "アクセス集中のため時間をおいて再度アクセスしてください"
        case .userNotFound: message = "ユーザが見つかりません"
        case .invalidEmail: message = "不正なメールアドレスです"
        case .emailAlreadyInUse: message = "このメールアドレスは既に使われています"
        case .wrongPassword: message = "入力した認証情報でサインインできません"
        case .userDisabled: message = "このアカウントは無効です"
        case .weakPassword: message = "パスワードが脆弱すぎます"
        // これは一例です。必要に応じて増減させてください
        default: break
        }
        return message
    }
    
    func showHomeView() {
        performSegue(withIdentifier: "toHomeView", sender: nil)
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
