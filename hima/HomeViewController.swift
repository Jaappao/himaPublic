//
//  HomeViewController.swift
//  hima
//
//  Created by 二本松秀樹 on 2021/02/25.
//

import UIKit
import Firebase
import FirebaseFirestoreSwift

class HomeViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet var nicknameLabel: UILabel!
    @IBOutlet var userIDLabel: UILabel!
    @IBOutlet var himaLabel: UILabel!
    @IBOutlet var busyLabel: UILabel!
    @IBOutlet var himaUISwitch: CustomUISwitch!
    @IBOutlet var thumbnailImageView: UIImageView!
    
    var myStatusHimajin: Himajin!
    var followingCollectionDataSource: [Himajin]!
    @IBOutlet var followingCollectionView: UICollectionView!
    
    var selectedHimajin: Himajin?
    
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.followingCollectionView.dataSource = self
        self.followingCollectionView.delegate = self
        self.followingCollectionView.register(UINib(nibName: "CustomCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "CustomCollectionViewCell")
        
        himaUISwitch.addTarget(self, action: #selector(isHimaSwitchTapped(_:)), for: .valueChanged)
        himaUISwitch.onTintColor = UIColor(displayP3Red: 0.203, green: 0.78, blue: 0.349, alpha: 0.8)
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.followingCollectionView.isHidden = true
        
        getMyStatusFromDB() { (himajin) in
            if let himajin = himajin {
                // データベースから正常にデータを取得できた時
                self.myStatusHimajin = himajin
                self.updateUI(himajin)
            } else {
                // データベースから正常にデータを取得できなかった時
                let alert = UIAlertController(title: "ごめんなさい", message: "無効なデータが見つかりました。再度ログインしてください。", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                    self.presentingViewController?.dismiss(animated: true, completion: nil)
                }))
            }
        }
        
        followingCollectionDataSource = [Himajin]()
        getMyFollowingHimajisFromDB { () in
            self.followingCollectionDataSource.sort {
                return $0.isHima && !$1.isHima
            }
            self.followingCollectionView.reloadData()
            self.followingCollectionView.fadeIn(type: .Normal, completed: nil)
        }
    }
    
    @objc private func isHimaSwitchTapped(_ sender: CustomUISwitch){
        let isHima = self.himaUISwitch.isOn
        print("\(isHima)")
        updateIsHimaOfDB(isHima) { (completed, date) in
            if completed {
                let newHimajin = Himajin(uid: self.myStatusHimajin.uid, userID: self.myStatusHimajin.userID, nickname: self.myStatusHimajin.nickname, thumbnailURL: self.myStatusHimajin.thumbnailURL, isHima: isHima, followPassword: self.myStatusHimajin.followPassword, createdAt: self.myStatusHimajin.createdAt, updatedAt: Date())
                self.myStatusHimajin = newHimajin
                self.updateHimaUI(isHima)
            }
        }
    }
    
    private func updateIsHimaOfDB(_ status: Bool, completion: @escaping (Bool, Date) -> Void) {
        print("[updateIsHima]")
        guard let user = Auth.auth().currentUser else {
            // サインインしていない場合の処理をするなど
            return
        }
        
        let myStatusRef = db.collection("users").document(user.uid)
        let updatedDate: Date = Date()
        myStatusRef.updateData([
            "is_hima": status,
            "updated_at": Timestamp(date: updatedDate)
        ]) { error in
            if let error = error {
                print("[updateIsHima] Error updating isHima \(error)")
                completion(false, updatedDate)
            }  else {
                print("[updateIsHima] isHima updated \(user.uid) - \(status)")
                completion(true, updatedDate)
            }
        }
    }
    
    func getMyStatusFromDB(completion: @escaping (Himajin?) -> Void){
        print("[getMyStatusFromDB]")
        guard let user = Auth.auth().currentUser else {
            // サインインしていない場合の処理をするなど
            return
        }
        
        print("[getMyStatusFromDB] DB connecting...")
        var me: Himajin!
        db.collection("users").document(user.uid).getDocument { (document, error) in
            if let document = document, document.exists {
                // データが存在していた時の処理
                print("[getMyStatusFromDB] \(user.uid) data existed")
                
                // Himajin型に型変換
                let result = Result {
                    try document.data(as: Himajin.self)
                }
                switch result {
                case .success(let himajin):
                    if let himajin = himajin {
                        print("[getMyStatusFromDB] Himajin: \(himajin.uid) \(himajin.nickname) \(himajin.userID) - \(himajin.isHima)")
                        completion(himajin)
                    } else {
                        print("[getMyStatusFromDB] Document does not Exist")
                    }
                case .failure(let error):
                    print("Error decoding Himajin: \(error)")
                }

            } else {
                // データが存在していなかった時(初回ログイン)の時の処理
                print("[getMyStatusFromDB] \(user.uid) data not exited - first login")

                let initialUserID = Useful.randomString(length: 15)
                
                // 重複しているUserIDがないかどうか確認
                DatabaseManager.checkUserIDUsed(initialUserID) { (isUsed, _) in
                    if isUsed {
                        completion(nil)
                    } else {
                        print("[getMyStatusFromDB] register unused UserID \(initialUserID)")
                        
                        // DBに保存
                        me = Himajin(uid: user.uid, userID: initialUserID, nickname: user.displayName!, thumbnailURL: "", isHima: false, followPassword: Useful.randomString(length: 6), createdAt: Date(), updatedAt: Date())
                        self.addHimajin(me, of: user)
                        completion(me)
                    }
                }
                
            }
        }
    }
    

    func addHimajin(_ himajin: Himajin, of user: User) {
        do {
            try db.collection("users").document(user.uid).setData(from: himajin)
        } catch let error {
            print("Error writing Himajim to Firestore: \(error)")
        }
    }
    
    private func updateUI(_ himajin: Himajin?) {
        if let himajin = himajin {
            nicknameLabel.text = himajin.nickname
            userIDLabel.text = "@" + himajin.userID
            self.updateHimaUI(himajin.isHima)
            
            // ImageViewの設定
            Useful.cropUIView(self.thumbnailImageView)
            DatabaseManager.setThumbnailImageView(photoURL: himajin.thumbnailURL, to: self.thumbnailImageView) { (_) in
                return
            }
            
        } else {
            let alert = UIAlertController(title: "ごめんなさい", message: "無効なデータが見つかりました。再度ログインしてください。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                self.presentingViewController?.dismiss(animated: true, completion: nil)
            }))
            print("[updateUI] 無効なデータが引き渡されました、再度ログインしてください")
        }
    }
    
    private func updateHimaUI(_ isHima: Bool) {
        himaLabel.isHidden = !isHima
        busyLabel.isHidden = isHima
        himaUISwitch.setOn(isHima, animated: true)
    }
    
    // -- CollectionView --
    
    // セルの数を設定
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("[collectionView - numofItemsinSection] \(followingCollectionDataSource.count)")
        return followingCollectionDataSource.count
    }
    
    // セルの内容をfollwingCollectionDataSourceから設定
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CustomCollectionViewCell", for: indexPath) as? CustomCollectionViewCell {
            
            // CollectionViewnのセルの内容を設定
            cell.userIDLabel.text = "@" + followingCollectionDataSource[indexPath.item].userID
            Useful.cropUIView(cell.thumbnailImageView)
            Useful.cropUIView(cell.backgroundUIView)
            DatabaseManager.setThumbnailImageView(photoURL: followingCollectionDataSource[indexPath.item].thumbnailURL, to: cell.thumbnailImageView) { (_) in
                return
            }
            if followingCollectionDataSource[indexPath.item].isHima {
                cell.backgroundUIView.backgroundColor = UIColor(red: 0.203, green: 0.78, blue: 0.349, alpha: 0.7)
            } else {
                cell.backgroundUIView.backgroundColor = .tertiarySystemGroupedBackground
            }
            
            return cell
        }
        return CustomCollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedHimajin = followingCollectionDataSource[indexPath.item]
        if selectedHimajin != nil {
            performSegue(withIdentifier: "toUserDetailsViewFromHome", sender: nil)
        }
    }
        
    // データベースから/users/{user_uid}/followingに入っているフォローしている人全てをfollowingCollectionDataSourceに格納
    func getMyFollowingHimajisFromDB(completion: @escaping () -> Void) {
        print("[getMyFollowingHimajinsFromDB]")
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        db.collection("users").document(user.uid).collection("following").getDocuments() { (querySnapshot, error) in
            if let error = error {
                print("[getMyFollowingHimajinsFromDB] Error gettting documents \(error)")
                return
            } else {
                if let documents = querySnapshot?.documents {
                    for document in documents {
                        // それぞれのフォローしている人の/users/{user_uid}ステータスを覗きにいく
                        self.getHimajinStatusFromDB(document.get("user_uid") as! String){ (himajin) in
                            if let himajin = himajin {
                                self.followingCollectionDataSource.append(himajin)
                                print("[getMyFollowingHimajinsFromDB] Successfully registered followingCollectionDataSource \(himajin.uid) \(himajin.userID) \(himajin.nickname)")
                                
                                // 非同期処理のため、最終ドキュメントのコンプリート時にcompletionを発行
                                if self.followingCollectionDataSource.count == documents.count {
                                    completion()
                                }
                            }
                        }
                    }
                    print("[getMyFollowingHimajinsFromDB] documents.count:\(documents.count) followingCollectionDataSource.count:\(self.followingCollectionDataSource.count)")
                }
            }
        }
    }
    
    func getHimajinStatusFromDB(_ userUID: String, completion: @escaping (Himajin?) ->Void) {
        print("[getHimajinStatusFromDB] \(userUID)")
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        db.collection("users").document(userUID).getDocument { (document, error) in
            if let error = error {
                print("[getHimajinStatusFromDB] Error getting documents \(error)")
            } else {
                if let document = document, document.exists {
                    // データが存在していた時の処理
                    print("[getHimajinStatusFromDB] \(user.uid) data existed")
                    
                    // Himajin型に型変換
                    let result = Result {
                        try document.data(as: Himajin.self)
                    }
                    switch result {
                    case .success(let himajin):
                        if let himajin = himajin {
                            print("[getHimajinStatusFromDB] Himajin: \(himajin.uid) \(himajin.nickname) \(himajin.userID) - \(himajin.isHima)")
                            completion(himajin)
                        } else {
                            print("[getHimajinStatusFromDB] Document does not Exist")
                        }
                    case .failure(let error):
                        print("Error decoding Himajin: \(error)")
                    }
                }
            }
        }
    }
    
    // ----- For Segue -----
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toConfigureUserStatusView" {
            let next = segue.destination as? ConfigureUserStatusViewController
            next?.myStatusHimajin = myStatusHimajin
        } else if segue.identifier == "toUserDetailsViewFromHome" {
            let next = segue.destination as? UserDetailsViewController
            next?.isTargetExistsInMyfollowing = true
            next?.targetHimajinInstance = selectedHimajin
        }
    }
    
}
