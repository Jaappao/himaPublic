//
//  UserDetailsViewController.swift
//  hima
//
//  Created by 二本松秀樹 on 2021/02/28.
//

import UIKit
import Firebase
import FirebaseFirestore

class UserDetailsViewController: UIViewController {
    
    @IBOutlet var thumbnailImageView: UIImageView!
    @IBOutlet var nicknameLabel: UILabel!
    @IBOutlet var userIDLabel: UILabel!
    
    @IBOutlet var isHimaUIView: UIView!
    @IBOutlet var isHimaLabel: UILabel!
    
    @IBOutlet var followPasswordTextField: UITextField!
    @IBOutlet var followButton: UIButton!
    
    var targetHimajinInstance: Himajin?
    var targetHimajinThumbnail: UIImage!
    
    var isTargetExistsInMyfollowing: Bool = false
    
    let db = Firestore.firestore()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        Useful.cropUIView(thumbnailImageView)
        Useful.cropUIView(isHimaUIView)
        
        
        if let targetHimajinInstance = targetHimajinInstance {
            setUI(targetHimajinInstance)
        }
        
    }
    
    
    @IBAction func followButtonTapped() {
        print("[followButtonTapped]")
        guard let targetHimajinInstance = self.targetHimajinInstance else {
            return
        }
        
        
        if isTargetExistsInMyfollowing {
            // アンフォロー処理
            self.followButton.isEnabled = false
            deleteTargetFromMyFollowing(targetHimajinInstance.uid) { (deleteCompleted) in
                if deleteCompleted {
                    self.isTargetExistsInMyfollowing = false //UI描画の条件分岐
                    self.setUI(targetHimajinInstance)
                } else {
                    self.isTargetExistsInMyfollowing = true
                    self.setUI(targetHimajinInstance)
                }
                self.followButton.isEnabled = true
            }
        } else {
            // フォロー処理
            if followPasswordTextField!.text == ""{
                followPasswordTextField.borderWidth = 3
                followPasswordTextField.borderColor = .systemRed
                print("[followButtonTapped] follow password is Empty")
            } else {
                self.followButton.isEnabled = false
                getTargetFollowPassword { (followPassword) in
                    if self.followPasswordTextField.text == followPassword {
                        self.addTargetHimajinFollowingArray(targetHimajinInstance.uid) {
                            self.isTargetExistsInMyfollowing = true
                            self.setUI(targetHimajinInstance)
                        }
                    } else {
                        print("[followButtonTapped] Invalid Password")
                        self.followButton.isEnabled = true
                    }
                }
            }
        }
        
    }
    
    
    // 最新のパスワードを改めて取得する
    func getTargetFollowPassword(completion: @escaping (String) -> Void){
        print("[getTargetFollowPassword]")
        guard let targetHimajinInstance = self.targetHimajinInstance else {
            return
        }
        
        guard let _ = Auth.auth().currentUser else {
            // サインインしていない場合の処理をするなど
            return
        }
        
        print("[getTargetFollowPassword] DB connecting...")
        db.collection("users").document(targetHimajinInstance.uid).getDocument { (snapshot, error) in
            if let error = error {
                print("Error getting documents \(error)")
                return
            } else {
                if let document = snapshot {
                    print("[getTargetFollowPassword] Successfully get password of \(targetHimajinInstance.uid)")
                    completion(document.get("follow_password") as! String)
                }
            }
        }
    }
    
    func deleteTargetFromMyFollowing(_ target_uid: String, completion: @escaping (Bool) -> Void) {
        print("[deleteTargetFromMyFollowing]")
        guard let _ = self.targetHimajinInstance else {
            return
        }
        
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        DatabaseManager.getfollowingRef(user.uid).document(target_uid).delete { (error) in
            if let error = error {
                print("Error deleting target \(error)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    // フォロー内にtargetが存在するかを調べる
    func isTargetExistsInMyFollowing(_ target_uid: String, completion: @escaping (Bool)->()) {
        guard let _ = self.targetHimajinInstance else {
            return
        }
        
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        DatabaseManager.getfollowingRef(user.uid).document(target_uid).getDocument { (documentSnapshot, error) in
            if let error = error {
                print("Error getting document \(error)")
                return
            } else {
                if let document = documentSnapshot, document.exists {
                    print("[isTargetExistsInMyFollowing] target \(target_uid) Exists in \(user.uid) following")
                    completion(true)
                } else {
                    print("[isTargetExistisInMyFollowing] target \(target_uid) not exists in \(user.uid) following")
                    completion(false)
                }
            }
        }
    }
    
    // targetが自分かどうかを調べる
    func checkTargetIsMe(_ target_uid: String, completion: @escaping (Bool) -> ()) {
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        completion(target_uid == user.uid)
    }
    
    func setUI(_ himajin: Himajin) {
        nicknameLabel.text = himajin.nickname
        userIDLabel.text = "@" + himajin.userID
        DatabaseManager.setThumbnailImageView(photoURL: himajin.thumbnailURL, to: self.thumbnailImageView) { (_) in
            return
        }
        isTargetExistsInMyFollowing(himajin.uid) { (isExists) in
            if isExists {
                self.followPasswordTextField.isEnabled = false
                self.followButton.isEnabled = true
                self.followButton.setTitle("フォロー中", for: .normal)
                self.followButton.setImage(.checkmark, for: .normal)
                self.followButton.backgroundColor = .none
                self.followButton.setTitleColor(UIColor(displayP3Red: 0.203, green: 0.78, blue: 0.349, alpha: 0.8), for: .normal)
                self.followButton.tintColor = UIColor(displayP3Red: 0.203, green: 0.78, blue: 0.349, alpha: 0.8)
                self.followButton.borderColor = .systemGroupedBackground
                self.followButton.isEnabled = true
                self.isTargetExistsInMyfollowing = true
                
                self.isHimaLabel.text = himajin.isHima ? "\(himajin.nickname)さんは、現在hima!です" : "\(himajin.nickname)さんは、現在busy...です"
                self.isHimaLabel.textColor = himajin.isHima ? UIColor(displayP3Red: 0.203, green: 0.78, blue: 0.349, alpha: 0.8) : UIColor.systemGray3
                self.isHimaUIView.backgroundColor = himajin.isHima ? UIColor(displayP3Red: 0.203, green: 0.78, blue: 0.349, alpha: 0.8) : UIColor.tertiarySystemGroupedBackground
                self.isHimaUIView.fadeIn(type: .Slow) {
                    self.isHimaLabel.fadeIn(type: .Normal, completed: nil)
                }
            } else {
                self.followPasswordTextField.isEnabled = true
                self.followPasswordTextField.text = ""
                self.followButton.setTitle("フォローする", for: .normal)
                self.followButton.setImage(.none, for: .normal)
                self.followButton.backgroundColor = UIColor(displayP3Red: 0.203, green: 0.78, blue: 0.349, alpha: 0.8)
                self.followButton.setTitleColor(.white, for: .normal)
                self.followButton.borderColor = UIColor(displayP3Red: 0.203, green: 0.78, blue: 0.349, alpha: 0.5)
                self.isTargetExistsInMyfollowing = false
                
                if !self.isHimaLabel.isHidden || !self.isHimaUIView.isHidden {
                    self.isHimaLabel.fadeOut(type: .Normal, completed: nil)
                    self.isHimaUIView.fadeOut(type: .Normal, completed: nil)
                }
                self.checkTargetIsMe(himajin.uid) { (isMe) in
                    if isMe {
                        self.followButton.isEnabled = false
                        self.followPasswordTextField.isEnabled = false
                        self.followButton.setTitle("あなたです", for: .normal)
                        self.followButton.setTitleColor(.none, for: .normal)
                        self.followButton.backgroundColor = .none
                        self.followButton.borderColor = .systemGroupedBackground
                    }
                }
            }
            self.followButton.fadeIn(type: .Slow, completed: nil)
        }
        
    }
    
    // /users/{user_uid}/following/* にターゲットのHimajinのuidを格納する
    func addTargetHimajinFollowingArray(_ targetUid: String, completion: @escaping () -> Void) {
        if targetUid == "" {
            return
        }
        
        guard let user = Auth.auth().currentUser else {
            // サインインしていない場合の処理をするなど
            return
        }
        
        db.collection("users").document(user.uid).collection("following").document(targetUid).setData( [
            "user_uid": targetUid,
            "created_at": Timestamp(date: Date())
        ]) { (error) in
            if let error = error {
                print("Error writing document \(error)")
            } else {
                print("[addTargetHimajinFollowingArray] Successfully added \(targetUid) in my followings")
                completion()
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}
