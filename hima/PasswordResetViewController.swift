//
//  PasswordResetViewController.swift
//  hima
//
//  Created by 二本松秀樹 on 2021/03/05.
//

import UIKit
import Firebase
import PKHUD

class PasswordResetViewController: UIViewController {
    
    @IBOutlet var sendPasswordResetMailButton: UIButton!
    @IBOutlet var emailTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func sendPasswordResetButtonTapped() {
        self.view.endEditing(true)
        if let email = emailTextField.text {
            if email.isEmpty {
                return
            }
            
            HUD.show(.progress)
            sendPasswordReset(email: email) {
                HUD.hide(animated: true)
                let alert = UIAlertController(title: "送信しました", message: "メールのリンクを確認してください\n届かない場合は迷惑フォルダも確認してください", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (UIAlertAction) in
                    self.view.endEditing(true)
                    self.presentingViewController?.dismiss(animated: true, completion: nil)
                }))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func sendPasswordReset(email: String, completion: @escaping () -> ()) {
        Auth.auth().sendPasswordReset(withEmail: email) { (error) in
            if let error = error {
                print("[passwordReset] Failed to Reset Password \(error)")
                return
            } else{
                print("[passwordReset] Successfully reset Password \(email)")
                completion()
            }
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}
