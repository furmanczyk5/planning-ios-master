//
//  SubtitleTableVIewCell.swift
//  planning-ios
//
//  Created by Matthew O'Connor on 2/24/17.
//  Copyright © 2017 American Planning Association. All rights reserved.
//

import UIKit

class SubtitleTableViewCell: UITableViewCell {
    
    @IBOutlet weak var title_label: UILabel!
    @IBOutlet weak var subtitle_label: UILabel!
    
    var title : String {
        get {
            return title_label.text ?? ""
        }
        set(newValue) {
            title_label.text = newValue ?? ""
        }
    }
    var subtitle : String {
        get {
            return subtitle_label.text ?? ""
        }
        set(newValue) {
            subtitle_label.text = newValue ?? ""
            
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
