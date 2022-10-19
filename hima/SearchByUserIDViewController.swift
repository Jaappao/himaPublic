//
//  SearchByUserIDViewController.swift
//  hima
//
//  Created by 二本松秀樹 on 2021/02/27.
//

import UIKit
import Firebase
import FirebaseFirestoreSwift

class SearchByUserIDViewController: UIViewController, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var searchBarField: UISearchBar!
    @IBOutlet var searchResultTableView: UITableView!
    
    var himajinFound: Bool?
    var searchResultDataSource: [Himajin]!
    
    let db = Firestore.firestore()
    
    var selectedHimajin: Himajin?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        searchResultTableView.register(UINib(nibName: "CustomTableViewCell", bundle: nil), forCellReuseIdentifier: "CustomCell")
        searchResultTableView.register(UINib(nibName: "EmptyStateTableViewCell", bundle: nil), forCellReuseIdentifier: "EmptyStateTableViewCell")
        searchResultTableView.dataSource = self
        searchResultTableView.delegate = self
        searchBarField.delegate = self
        searchBarField.autocapitalizationType = .none
        searchBarField.backgroundImage = UIImage()
            
        searchResultDataSource = [Himajin]()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // キーボードを閉じる
        view.endEditing(true)
        
        if let word = searchBar.text{
            getHimajinsByUserID(word) { (isFound) in
                self.himajinFound = isFound
                self.searchResultTableView.reloadData()
            }
        }
    }
    
    func getHimajinsByUserID(_ userID: String, completion: @escaping (Bool) -> Void) {
        print("[getHimajinsByUserID] \(userID)")
        var isFound: Bool = false
        
        db.collection("users").whereField("user_id", isEqualTo: userID).getDocuments { (querySnapshot, error) in
            print("[getHimajinsByUserID] getDocuments Completion")
            if let error = error {
                print("Error getting documents: \(error)")
                isFound = false
            } else {
                var himajinSearchResult = [Himajin]()
                for document in querySnapshot!.documents {
                    let result = Result{
                        try document.data(as: Himajin.self)
                    }
                    switch result{
                    case .success(let himajin):
                        if let himajin = himajin {
                            // 無事にユーザーIDと一致するユーザーを発見した
                            himajinSearchResult.append(himajin)
                            
                            print("[getHimajinsByUserID] Successfully get \(himajin.uid) \(himajin.userID) \(himajin.nickname)")
                            isFound = true
                        }
                    case .failure(let error):
                        print("Error decoding Himajin: \(error)")
                    }
                }
                self.searchResultDataSource = himajinSearchResult
                
            }
            completion(isFound)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let himajinFound = himajinFound {
            if himajinFound {
                if let searchResultDataSource = self.searchResultDataSource {
                    return searchResultDataSource.count
                }
            }
            return 1 // 検索結果がなかったとき
        }
        return 0 //初期ビューロード時
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("[tableView - collForRowAt] \(himajinFound)")
        if let himajinFound = himajinFound{
            if himajinFound {
                if let cell = searchResultTableView.dequeueReusableCell(withIdentifier: "CustomCell") as? CustomTableViewCell {
                    cell.nicknameLabel.text = searchResultDataSource[indexPath.row].nickname
                    cell.userIDLabel.text = "@" + searchResultDataSource[indexPath.row].userID
                    Useful.cropUIView(cell.thumbnailImageView)
                    DatabaseManager.setThumbnailImageView(photoURL: searchResultDataSource[indexPath.row].thumbnailURL, to: cell.thumbnailImageView) { (_) in //画像設定のない人やエラーはnilが入る
                        return
                    }
                    return cell // 検索結果を表示
                }
                return UITableViewCell() // セルになんらかの異常が発生したとき
            } else {
                if let cell = searchResultTableView.dequeueReusableCell(withIdentifier: "EmptyStateTableViewCell") as? EmptyStateTableViewCell{
                    return cell
                }
                return EmptyStateTableViewCell() // 検索結果がなかったとき
            }
        }
        return UITableViewCell() //初回ビューロード時
    }
    
    // UserDetailsViewに選択したデータを送信する
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toUserDetailsViewFromSearch" {
            let next = segue.destination as? UserDetailsViewController
            next?.targetHimajinInstance = selectedHimajin
        }
    }
    
    // Cellを選択した時の動作
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let himajinFound = himajinFound{
            if himajinFound {
                selectedHimajin = searchResultDataSource[indexPath.row]
                if selectedHimajin != nil {
                    performSegue(withIdentifier: "toUserDetailsViewFromSearch", sender: nil)
                }
            }
        }
    }
}
