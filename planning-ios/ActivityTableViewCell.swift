//
//  ActivityTableViewCell.swift
//  planning-ios
//
//  Created by Matthew O'Connor on 2/13/15.
//  Copyright (c) 2015 American Planning Association. All rights reserved.
//

import UIKit

class ActivityTableViewCell: UITableViewCell {
    
    @IBOutlet weak var time_label: UILabel!
    @IBOutlet weak var title_label: UILabel!
    @IBOutlet weak var description_label: UILabel!
    @IBOutlet weak var cm_view: UIView!
    @IBOutlet weak var cm_label: UILabel!
    @IBOutlet weak var cm_law_label: UILabel!
    @IBOutlet weak var cm_ethics_label: UILabel!
    @IBOutlet weak var cm_law_logo: UILabel!
    @IBOutlet weak var cm_ethics_logo: UILabel!
    
    @IBOutlet weak var tag_location_label: UILabel!
    @IBOutlet weak var prices_label: UILabel!
    
    //@IBOutlet weak var tags_label: UILabel!
    //@IBOutlet weak var subtitle_label: UILabel!
    @IBOutlet weak var speakers_label: UILabel!
    @IBOutlet weak var ticket_view: UIView!
    @IBOutlet weak var ticket_image: UIImageView!
    @IBOutlet weak var head_view: UIView!
    
    @IBOutlet weak var cm_law_width_constraint: NSLayoutConstraint!
    @IBOutlet weak var cm_law_height_constraint: NSLayoutConstraint!
    @IBOutlet weak var cm_ethics_width_constraint: NSLayoutConstraint!
    @IBOutlet weak var cm_ethics_height_constraint: NSLayoutConstraint!
    
    @IBOutlet weak var ticket_view_width_contraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setContent(_ activity: Activity) {
        
        title_label.text = activity.title
        tag_location_label!.text = activity.tag_location
        description_label!.text = activity.description_string
        
        let cm = activity.cm as Double
        
        if cm > 0.00 {
            
            cm_label.text = cm.truncatingRemainder(dividingBy: 1) == 0 ? String(format:"%.0f", cm) : String(format:"%.2f", cm)
            cm_view.isHidden = false
            
            let cm_law = activity.cm_law as Double
            let cm_ethics = activity.cm_ethics as Double
            
            //assuming that cm_law/cm_ethics is always equal to cm approved
            if cm_law > 0.00 {
                cm_law_label.text = cm_law.truncatingRemainder(dividingBy: 1) == 0 ? String(format:"%.0f", cm_law) : String(format:"%.2f", cm_law)
                cm_law_logo.layer.cornerRadius = 2.0
                cm_law_logo.layer.masksToBounds = true
                cm_law_width_constraint.constant = 58
                cm_law_height_constraint.constant = 14
            }else{
                cm_law_width_constraint.constant = 0
                cm_law_height_constraint.constant = 0
            }
            
            if cm_ethics > 0.00 {
                cm_ethics_label.text = cm_ethics.truncatingRemainder(dividingBy: 1) == 0 ? String(format:"%.0f", cm_ethics) : String(format:"%.2f", cm_ethics)
                cm_ethics_logo.layer.cornerRadius = 2.0
                cm_ethics_logo.layer.masksToBounds = true
                cm_ethics_width_constraint.constant = 58
                cm_ethics_height_constraint.constant = 14
            }else{
                cm_ethics_width_constraint.constant = 0
                cm_ethics_height_constraint.constant = 0
            }

        }else{
            cm_view.isHidden = true
            cm_law_width_constraint.constant = 0
            cm_law_height_constraint.constant = 0
            cm_ethics_width_constraint.constant = 0
            cm_ethics_height_constraint.constant = 0
        }
        
        ticket_image.tintColor = UIColor.orange
        
        if activity.has_product.boolValue {
            let prices_text = activity.price_list.map({"\($0.name):\n$\($0.price)"}).joined(separator:"\n")
            prices_label.text = prices_text
            ticket_view_width_contraint.constant = 58
            ticket_view.sizeToFit()
        }else{
            ticket_view_width_contraint.constant = 0
        }
    
//        time_label.backgroundColor = UIColor(red: 0.85, green: 0.75, blue: 0.75, alpha: 0.8)
//        title_label.backgroundColor = UIColor(red: 0.75, green: 0.85, blue: 0.75, alpha: 0.8)
//        cm_view.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.45, alpha: 0.8)
//        cm_label.backgroundColor = UIColor(red: 0.75, green: 0.85, blue: 0.85, alpha: 0.8)
//        tag_location_label.backgroundColor = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 0.8)
//        ticket_view.backgroundColor = UIColor(red: 0.85, green: 0.95, blue: 0.65, alpha: 0.8)
//        head_view.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.65, alpha: 0.8)
        
        time_label.text = activity.time_string
        
        if activity.speakers.count == 0 {
            speakers_label.isHidden = true
        }else{
            var speakers_string : String = ""
            for (i, speaker) in activity.speakers.enumerated() {
                speakers_string += (speaker as AnyObject).title
                if i < activity.speakers.count - 1 {
                    speakers_string += " | "
                }
            }
            speakers_label.text = speakers_string
            speakers_label.isHidden = false
        }
    }

}
