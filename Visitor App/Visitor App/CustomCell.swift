//
//  CustomCell.swift
//  Visitor App
//
//  Created by Gill, Nathan on 28/11/2023.
//

import UIKit

class CustomCell: UITableViewCell {

    @IBOutlet weak var imgFav: UIImageView!
    @IBOutlet weak var imgPlant: UIImageView!
    @IBOutlet weak var txtMain: UILabel!
    @IBOutlet weak var txtSec: UILabel!
    @IBOutlet weak var recnumHdn: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
            imgFav.image = UIImage(named: "fav")
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
