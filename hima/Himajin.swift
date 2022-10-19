//
//  Himajin.swift
//  hima
//
//  Created by 二本松秀樹 on 2021/02/25.
//

import Foundation
import Firebase

public struct Himajin: Codable {
    let uid: String
    let userID: String
    let nickname: String
    let thumbnailURL: String
    let isHima: Bool
    let followPassword: String
    let createdAt: Timestamp
    let updatedAt: Timestamp
    
    enum CodingKeys: String, CodingKey {
        case uid
        case userID = "user_id"
        case nickname
        case thumbnailURL = "thumbnail_url"
        case isHima = "is_hima"
        case followPassword = "follow_password"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(uid: String, userID: String, nickname: String, thumbnailURL: String, isHima: Bool, followPassword: String, createdAt: Date, updatedAt: Date) {
        self.uid = uid
        self.userID = userID
        self.nickname = nickname
        self.thumbnailURL = thumbnailURL
        self.isHima = isHima
        self.followPassword = followPassword
        self.createdAt = Timestamp(date: createdAt)
        self.updatedAt = Timestamp(date: updatedAt)
    }
    
    init(uid: String, userID: String, nickname: String, thumbnailURL: String, isHima: Bool, followPassword: String, createdAt: Timestamp, updatedAt: Date) {
        self.uid = uid
        self.userID = userID
        self.nickname = nickname
        self.thumbnailURL = thumbnailURL
        self.isHima = isHima
        self.followPassword = followPassword
        self.createdAt = createdAt
        self.updatedAt = Timestamp(date: updatedAt)
    }
    
    func getCreatedAt() -> Date {
        return self.createdAt.dateValue()
    }
    
    func getUpdatedAt() -> Date {
        return self.updatedAt.dateValue()
    }
    
    // データベースの更新を行い、差し替え用のHimajin構造体を返すだけ、配列の要素の差し替えはclosureで行う
    func updateThumbnail(_ image: UIImage, completion: @escaping (Himajin) -> Void) {
        DatabaseManager.uploadThumbnailImage(image, of: self.uid) { (thumbnailURL) -> (Void) in
            if thumbnailURL.isEmpty {
                print("[Himajin - setThumbnail] Error uploading ThumbnailImage")
                return
            }
            let afterHimajin = Himajin(uid: self.uid, userID: self.userID, nickname: self.nickname, thumbnailURL: thumbnailURL, isHima: self.isHima, followPassword: self.followPassword, createdAt: self.createdAt, updatedAt: Date())
            completion(afterHimajin)
        }
    }
}
