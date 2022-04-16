//
//  ActivityDetailsNativeViewController.swift
//  planning-ios
//
//  Created by Matthew O'Connor on 3/23/15.
//  Copyright (c) 2015 American Planning Association. All rights reserved.
//

import UIKit

class ActivityDetailNativeViewController: ActivityDetailViewController {
    
    @IBOutlet weak var title_label: UILabel!
    @IBOutlet weak var subtitle_label: UILabel!
    @IBOutlet weak var begin_time_label: UILabel!
    @IBOutlet weak var end_time_label: UILabel!
    @IBOutlet weak var location_label: UILabel!
    
    @IBOutlet weak var description_label: UILabel!
    @IBOutlet weak var speakers_label: UILabel!
    @IBOutlet weak var tags_label: UILabel!
    @IBOutlet weak var id_label: UILabel!
    
    @IBOutlet weak var cm_container: UIView!
    @IBOutlet weak var cm_value: UILabel!
    @IBOutlet weak var cm_law_label: UILabel!
    @IBOutlet weak var cm_law_value: UILabel!
    @IBOutlet weak var cm_ethics_label: UILabel!
    @IBOutlet weak var cm_ethics_value: UILabel!
    
    @IBOutlet weak var ticket_view: UIView!
    @IBOutlet weak var prices_label: UILabel!
    @IBOutlet weak var ticket_image: UIImageView!
    
    //constraint outlets
    @IBOutlet weak var cm_height_constraint: NSLayoutConstraint!
    @IBOutlet weak var cm_width_constraint: NSLayoutConstraint!
    @IBOutlet weak var cm_law_height_constraint: NSLayoutConstraint!
    @IBOutlet weak var cm_law_width_constraint: NSLayoutConstraint!
    @IBOutlet weak var cm_ethics_height_constraint: NSLayoutConstraint!
    @IBOutlet weak var cm_ethics_width_constraint: NSLayoutConstraint!
    
    @IBOutlet weak var ticket_width_constraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        set_native_fields()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func set_native_fields() {
        if activity != nil {
            
            title_label.text = activity!.title
            title_label.lineBreakMode = NSLineBreakMode.byWordWrapping
//            title_label.sizeToFit()
            
            subtitle_label.text = activity!.subtitle
            subtitle_label.lineBreakMode = NSLineBreakMode.byWordWrapping
//            subtitle_label.sizeToFit()
            
            location_label.text = activity!.tag_location
            location_label.lineBreakMode = NSLineBreakMode.byWordWrapping
//            location_label.sizeToFit()
            
            description_label.text = activity!.description_string
            description_label.lineBreakMode = NSLineBreakMode.byWordWrapping
//            description_label.sizeToFit()
            
            // CM CREDITS
            if activity!.cm as Double > 0.00 {
                cm_value.text = String(format:"%.2f", activity!.cm as Double)
                cm_height_constraint.constant = 26
                cm_width_constraint.constant = 94
            }else{
                cm_height_constraint.constant = 0
                cm_width_constraint.constant = 0
            }
            
            // CM LAW CREDITS
            if activity!.cm_law as Double > 0.00 {
                cm_law_value.text = String(format:"%.2f", activity!.cm_law as Double)
                cm_law_label.layer.cornerRadius = 3.0
                cm_law_label.layer.masksToBounds = true
                
                cm_law_height_constraint.constant = 26
                cm_law_width_constraint.constant = 88
            }else{
                cm_law_height_constraint.constant = 0
                cm_law_width_constraint.constant = 0
            }
            
            // CM ETHICS CREDITS
            if activity!.cm_ethics as Double > 0.00 {
                cm_ethics_value.text = String(format:"%.2f", activity!.cm_ethics as Double)
                cm_ethics_label.layer.cornerRadius = 3.0
                cm_ethics_label.layer.masksToBounds = true
                
                cm_ethics_height_constraint.constant = 26
                cm_ethics_width_constraint.constant = 88
            }else{
                cm_ethics_height_constraint.constant = 0
                cm_ethics_width_constraint.constant = 0
            }
            
            id_label.text = "#\(activity!.id)"
//            code_label.sizeToFit()

            begin_time_label.text = activity!.begin_time?.date_time_short_user_friendly(timezone:appCore.timeZoneName)
            
            end_time_label.text = activity!.end_time?.date_time_short_user_friendly(timezone:appCore.timeZoneName)
            
            if activity!.has_product.boolValue {
                let prices_text = activity!.price_list.map({"\($0.name):\n$\($0.price)"}).joined(separator:"\n")
                print(prices_text)
                prices_label.text = prices_text
                ticket_image.tintColor = UIColor.orange
                ticket_view.sizeToFit()
            }else{
                ticket_width_constraint.constant = 0
            }
            
            
            let tags_array = activity!.tags.components(separatedBy: ",")
            if tags_array.isEmpty {
                tags_label.superview!.isHidden = true
            }else{
                var tags_string : String = ""
                for (i, tag) in tags_array.enumerated() {
                    tags_string += tag
                    if i < tags_array.count - 1 {
                        tags_string += "\n"
                    }
                }
                tags_label.text = tags_string
                tags_label.lineBreakMode = NSLineBreakMode.byWordWrapping
                tags_label.sizeToFit()
                tags_label.isHidden = false
            }
            
            if activity!.speakers.count == 0 {
                speakers_label.superview!.isHidden = true
            }else{
                var speakers_string : String = ""
                for (i, speaker) in activity!.speakers.enumerated() {
                    speakers_string += (speaker as AnyObject).title
                    if i < activity!.speakers.count - 1 {
                        speakers_string += "\n"
                    }
                }
                speakers_label.text = speakers_string
                speakers_label.lineBreakMode = NSLineBreakMode.byWordWrapping
                speakers_label.sizeToFit()
                speakers_label.isHidden = false
            }
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
