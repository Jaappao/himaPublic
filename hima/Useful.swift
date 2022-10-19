//
//  Useful.swift
//  hima
//
//  Created by 二本松秀樹 on 2021/03/03.
//

import Foundation
import UIKit

class Useful {
    static let defaultUserIconName = "defaultUserIcon"

    
    static func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    static func cropUIView(_ uiView: UIView) {
        uiView.layer.cornerRadius = uiView.frame.width * 0.5 // 円形にくり抜く
    }
}
