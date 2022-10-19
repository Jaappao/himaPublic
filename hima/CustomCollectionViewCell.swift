//
//  CustomCollectionViewCell.swift
//  hima
//
//  Created by 二本松秀樹 on 2021/03/01.
//

import UIKit

class CustomCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var thumbnailImageView: UIImageView!
    @IBOutlet var userIDLabel: UILabel!
    @IBOutlet var backgroundUIView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
