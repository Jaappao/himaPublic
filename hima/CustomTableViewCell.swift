//
//  TableViewCell.swift
//  hima
//
//  Created by 二本松秀樹 on 2021/02/27.
//

import UIKit

class CustomTableViewCell: UITableViewCell {
    
    @IBOutlet var nicknameLabel: UILabel!
    @IBOutlet var userIDLabel: UILabel!
    @IBOutlet var thumbnailImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    

    
}
