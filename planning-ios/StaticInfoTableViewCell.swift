//
//  StaticInfoTableViewCell.swift
//  planning-ios
//
//  Created by Matthew O'Connor on 3/27/15.
//  Copyright (c) 2015 American Planning Association. All rights reserved.
//

import UIKit

class StaticInfoTableViewCell: UITableViewCell {

    @IBOutlet weak var message_label: UILabel!
    @IBOutlet weak var sponsorButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setContent(_ context:AnyObject?) {
        
        if let content = context as? Content {
            message_label.text = content.text
        }
        
    }
    
//    @IBAction func cellImageTapped(_ sender: AnyObject) {
//        UIApplication.shared.openURL(URL(string:"http://www.aecom.com/")!)
//    }

}
