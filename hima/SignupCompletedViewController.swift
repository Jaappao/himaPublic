//
//  SignupCompletedViewController.swift
//  hima
//
//  Created by 二本松秀樹 on 2021/02/25.
//

import UIKit
import Firebase

class SignupCompletedViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction private func resend() {
        guard let user = Auth.auth().currentUser else {
            return
        }
        self.resendEmailVerification(to: user)
    }
    
    
    private func resendEmailVerification(to user: User) {
        user.sendEmailVerification { [weak self]error in
            guard let self = self else { return }
            if error == nil {
                // Resend
                print("[resendEmailVerification] Completed")
                let alert: UIAlertController = UIAlertController(title: "再送完了", message: "迷惑フォルダなどもご確認ください", preferredStyle: .alert)
                let defaultAction: UIAlertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(defaultAction)
                self.present(alert, animated: true, completion: nil)
            }
            DatabaseManager.showError(error, viewController: self)
        }
    }
    
    @IBAction private func returnToLoginView() {
        self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
    }
}
