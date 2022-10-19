//
//  ConfigureUserStatusViewController.swift
//  hima
//
//  Created by 二本松秀樹 on 2021/03/01.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import CropViewController
import SDWebImage
import PKHUD

class ConfigureUserStatusViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CropViewControllerDelegate {
    
    @IBOutlet var nicknameTextField: UITextField!
    @IBOutlet var userIDTextField: UITextField!
    @IBOutlet var thumbnailImageView: UIImageView!
    @IBOutlet var followPasswordTextField: UITextField!
    @IBOutlet var logoutButton: UIButton!
    
    @IBOutlet var changeThumbnailButton: UIButton!
    @IBOutlet var saveButton: UIBarButtonItem!
    
    var imagePickerController: UIImagePickerController = UIImagePickerController()
    
    var myStatusHimajin: Himajin! // ビュー初期化時点で代入されたものから変化しない
    var myThumbnail: UIImage? // ImagePickerで選択されて初めて代入される、データベース送信のソース

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let user = Auth.auth().currentUser else {
            return
        }

        // Do any additional setup after loading the view.
        if let myStatusHimajin = myStatusHimajin {
            nicknameTextField.text = myStatusHimajin.nickname
            userIDTextField.text = myStatusHimajin.userID
            followPasswordTextField.text = myStatusHimajin.followPassword
            Useful.cropUIView(self.thumbnailImageView)
            DatabaseManager.setThumbnailImageView(photoURL: self.myStatusHimajin.thumbnailURL, to: self.thumbnailImageView) { (_) in
                return
            }
        } else {
            // 初回ログイン時の挙動(稀の挙動)
            myStatusHimajin = Himajin(uid: user.uid, userID: "", nickname: user.displayName ?? "" , thumbnailURL: "", isHima: false, followPassword: "", createdAt: Date(), updatedAt: Date())
        }
    }
    
    @IBAction func logoutButtonTapped() {
        HUD.show(.progress, onView: self.logoutButton)
        print("[logoutButtonTapped]")
        do {
            try Auth.auth().signOut()
            print("[loguoutButtonTapped] Successfully logout")
            HUD.hide(animated: true)
            self.returnToLoginView()
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
        HUD.hide(animated: true)
    }
    
    func returnToLoginView() {
        print("[returnToLoginView]")
//        let storyboard = UIStoryboard(name: "Main", bundle: nil)
//        let loginViewController = storyboard.instantiateViewController(identifier: "SigninViewController") as! SigninViewController
//        loginViewController.modalPresentationStyle = .fullScreen
//        loginViewController.modalTransitionStyle = .coverVertical
//
//        self.present(loginViewController, animated: true, completion: nil)
        
        navigationController?.popViewControllers(viewsToPop: 2)
    }
    
    @IBAction func choosePhotoButtonTapped() {
        print("[choosePhotoButtonTapped]")
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            imagePickerController.sourceType = UIImagePickerController.SourceType.photoLibrary
            imagePickerController.delegate = self
            imagePickerController.allowsEditing = false
            present(imagePickerController, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        print("[imagePickerController]")
        guard let pickerImage = (info[UIImagePickerController.InfoKey.originalImage] as? UIImage) else {
            return
        }
        
        let cropController = CropViewController(croppingStyle: .default, image: pickerImage)
        cropController.delegate = self
        cropController.customAspectRatio = CGSize(width: 100, height: 100)
        
//        cropController.aspectRatioLockEnabled = true
        cropController.aspectRatioPickerButtonHidden = true
        cropController.resetAspectRatioEnabled = false
        cropController.rotateButtonsHidden = true
        cropController.cropView.cropBoxResizeEnabled = false
        
        imagePickerController.dismiss(animated: true) {
            self.present(cropController, animated: true, completion: nil)
        }
    }
    
    func cropViewController(_ cropViewController: CropViewController, didFinishCancelled cancelled: Bool) {
        print("[cropViewController - didFinishCancelled]")
        cropViewController.dismiss(animated: true) {
            self.present(self.imagePickerController, animated: true, completion: nil)
        }
    }
    
    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        print("[cropViewController - didCropToImage]")
        // 'image' is the newly cropped version of the original image
        myThumbnail = image
        thumbnailImageView.image = image
        cropViewController.dismiss(animated: true, completion: nil)
    }

    
    @IBAction func saveButtonTapped() {
        print("[saveButtonTapped]")
        
        HUD.show(.progress)
        self.view.endEditing(true)
        // Validation
        if !isValidNickname() || !isValidUserID() || !isValidFollowPassword() {
            HUD.flash(.labeledError(title: nil, subtitle: "入力値を確認してください"))
            print("[saveButtonTapped] is not valid field")
            return
        }
        
        if userIDTextField.text != self.myStatusHimajin.userID {
            // ユーザーIDの変更をした場合はUserIDの衝突チェック
            DatabaseManager.checkUserIDUsed(self.userIDTextField!.text!) { (isFound, querySnapshot) in
                if isFound {
                    // 見つかった場合
                    HUD.hide(animated: true)
                    let alert = UIAlertController(title: "入力されているUserIDは使用できません", message: "別のUserIDを指定してください", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                } else {
                    // 衝突するIDが見つからなかった場合
                    self.executeSave()
                }
            }
        } else {
            // ユーザーIDの変更をしていない場合
            self.executeSave()
        }
    }
    
    func executeSave(){
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        
        if let myThumbnail = myThumbnail {
            // 画像の更新が行われた場合(imagePickerでmyThumbnailに代入が行われているはず)は先に画像を保存してそのあとURLを添えてFirestoreに投げる
            SDImageCache.shared.removeImageFromDisk(forKey: myStatusHimajin.thumbnailURL)
            DatabaseManager.uploadThumbnailImage(myThumbnail, of: user.uid) { (thumbnailURL) -> (Void) in
                let himajin = Himajin(
                    uid: user.uid,
                    userID: self.userIDTextField!.text!,
                    nickname: self.nicknameTextField!.text!,
                    thumbnailURL: thumbnailURL, // ここが違う
                    isHima: self.myStatusHimajin.isHima,
                    followPassword: self.followPasswordTextField!.text!,
                    createdAt: self.myStatusHimajin.createdAt,
                    updatedAt: Date()
                )
                DatabaseManager.updateHimajin(himajin, of: user){
                    HUD.flash(.success, onView: self.view, delay: 1.0) { (_) in
                        self.navigationController?.popViewControllers(viewsToPop: 1)
                        print("[saveButtonTapped] return to Home")
                    }
                }
            }
        } else {
            // 画像の更新が行われなかった場合
            let himajin = Himajin(
                uid: user.uid,
                userID: self.userIDTextField!.text!,
                nickname: self.nicknameTextField!.text!,
                thumbnailURL: self.myStatusHimajin.thumbnailURL,
                isHima: self.myStatusHimajin.isHima,
                followPassword: self.followPasswordTextField!.text!,
                createdAt: self.myStatusHimajin.createdAt,
                updatedAt: Date()
            )
            DatabaseManager.updateHimajin(himajin, of: user){
                DatabaseManager.updateHimajin(himajin, of: user){
                    HUD.flash(.success, onView: self.view, delay: 1.0) { (_) in
                        self.navigationController?.popViewControllers(viewsToPop: 1)
                        print("[saveButtonTapped] return to Home")
                    }
                }
            }
        }
    }
    
    func isValidNickname() -> Bool {
        if nicknameTextField.text!.isEmpty {
            return false
        }
        
        if nicknameTextField.text!.lengthOfBytes(using: .utf8) < 2 {
            return false
        }
        
        if nicknameTextField.text!.lengthOfBytes(using: .utf8) > 25 {
            return false
        }
        
        return true
    }
    
    func isValidUserID() -> Bool {
        if userIDTextField.text!.isEmpty {
            return false
        }
        
        if userIDTextField.text!.lengthOfBytes(using: .utf8) < 2 {
            return false
        }
        
        if userIDTextField.text!.lengthOfBytes(using: .utf8) > 50 {
            return false
        }
        
        return true
    }
    
    func isValidFollowPassword() -> Bool {
        if followPasswordTextField.text!.isEmpty {
            return false
        }
        
        if followPasswordTextField.text!.lengthOfBytes(using: .utf8) < 4 {
            return false
        }
        
        if followPasswordTextField.text!.lengthOfBytes(using: .utf8) > 200 {
            return false
        }
        
        return true
    }

    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}

extension UINavigationController {

    func popToViewController(ofClass: AnyClass, animated: Bool = true) {
        if let vc = viewControllers.filter({$0.isKind(of: ofClass)}).last {
            popToViewController(vc, animated: animated)
        }
    }

    func popViewControllers(viewsToPop: Int, animated: Bool = true) {
        if viewControllers.count > viewsToPop {
            let vc = viewControllers[viewControllers.count - viewsToPop - 1]
            popToViewController(vc, animated: animated)
        }
    }
}
