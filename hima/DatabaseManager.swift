//
//  DetabaseManager.swift
//  hima
//
//  Created by 二本松秀樹 on 2021/03/03.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseUI

class DatabaseManager {
    
    static let db = Firestore.firestore() // Firebase Firestore
    static let usersRef = db.collection("users")
    static func getfollowingRef(_ uid: String) -> CollectionReference {
        return usersRef.document(uid).collection("following")
    }
    
    static let storageThumbnailPath = "thumbnail/"
    static let storage = Storage.storage() // Firebase Storage
    static let storageRef = storage.reference()
    static let maxFileSize: Double = 100.0 //KB
    
    
    // --- Firebase Store ----
    static func uploadThumbnailImage(_ image: UIImage?, of user_uid: String, completion: @escaping (String)->(Void)) {
        print("[DBMNG - uploadThumbnailImage] \(user_uid)")
        guard let _ = Auth.auth().currentUser else {
            return
        }
        
        guard var imageData = image?.jpegData(compressionQuality: 1) ?? nil else {
            return
        }
        
        var dataKB = Double(NSData(data: imageData).count) / 1000.0
        if dataKB > maxFileSize {
            let compressonQuality: CGFloat = 0.5
            
            let resizedImage = image!.resize(targetSize: CGSize(width: 200.0, height: 200.0))
            imageData = resizedImage.jpegData(compressionQuality: compressonQuality)!
            
            dataKB = Double(NSData(data: imageData).count) / 1000.0
            print("[uploadThumbnailImage] Compressed Image \(compressonQuality) \(dataKB)")
        }
        
        let imageRef = storageRef.child("\(storageThumbnailPath)\(user_uid).jpg")
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpeg"
        
        imageRef.putData(imageData, metadata: metaData) { (metaData, error) in
            if let error = error {
                print("Error uploading image \(error)")
                return
            } else {
                imageRef.downloadURL { (url, error) in
                    if let error = error {
                        print("Error dowinloading URL \(error)")
                        return
                    } else {
                        guard let url = url else {
                            return
                        }
                        
                        print("[DBMNG - uploadThumbnailImage] Successfully uploaded \(user_uid).jpg")
                        completion(url.absoluteString)
                    }
                }
            }
        }
    }
    
    // 引数のimageViewにアイコンをセットするところまで行う
    static func setThumbnailImageView(photoURL: String, to: UIImageView, completion: @escaping(UIImage?) -> ()){
        print("[DBMNG - setThumbnailImageView] \(photoURL)")
        guard let _ = Auth.auth().currentUser else {
            return
        }
        
        if photoURL.isEmpty {
            print("[DBMNG - setThumbnailImageView] photoURL is empty")
            to.image = UIImage(named: Useful.defaultUserIconName)
            completion(nil)
            return
        }
        
        let imageRef = storage.reference(forURL: photoURL)
        let placeholderImage = UIImage(named: "defaultUserIcon")
        to.sd_setImage(with:imageRef, maxImageSize: 1 * 1024 * 1024, placeholderImage: placeholderImage, options: SDWebImageOptions.refreshCached) { (image, error, _, _) in
            if let error = error {
                print("Error setting thumbnail \(photoURL) - \(error)")
                completion(nil)
            } else {
                print("[DBMNG - setThumbnailImageView] Successgully set \(photoURL)")
                completion(image)
            }
        }
    }
    
    
    // ----- Firestore -----
    static func updateHimajin(_ himajin: Himajin, of user: User, completion: () -> ()) {
        print("[DBMNG - updateHimajin] \(user.uid)")
        do {
            try db.collection("users").document(user.uid).setData(from: himajin)
            print("[DBMNG - updateHimajin] Successfully updateed Himajin \(user.uid)")
            completion()
        } catch let error {
            print("Error writing Himajim to Firestore: \(error)")
        }
    }
    
    static func showError(_ errorOrNil: Error?, viewController: UIViewController) {
        // エラーがなければ何もしない
        guard let error = errorOrNil else { return }
        
        let message = errorMessage(of: error)
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        viewController.present(alert, animated: true, completion: nil)
    }
    
    static func checkUserIDUsed(_ userID: String, completion: @escaping (Bool, QuerySnapshot?) -> Void) {
        print("[checkUserIDUsed]")
        var isUsed: Bool = true
        
        db.collection("users").whereField("user_id", isEqualTo: userID).getDocuments { (querySnapshot, error) in
            print("[checkUserIDUsed] getDocuments Completion")
            if let error = error {
                print("Error getting documents: \(error)")
                isUsed = true
            } else {
                if querySnapshot!.documents.isEmpty {
                    print("[checkUserIDUsed] \(userID) is unused")
                    isUsed = false
                } else {
                    print("[checkUserIDUsed] \(userID) is used")
                    isUsed = true
                }
            }
            completion(isUsed, querySnapshot)
        }
    }
    
    static func errorMessage(of error: Error) -> String {
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
        // これは一例です。必要に応じて増減させてください
        default: break
        }
        return message
    }
}

extension UIImage {

    func resize(targetSize: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size:targetSize).image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

}
