//
//  ActivityDetailViewController.swift
//  planning-ios
//
//  Created by Matthew O'Connor on 2/17/15.
//  Copyright (c) 2015 American Planning Association. All rights reserved.
//

import UIKit

class ActivityDetailViewController: UIViewController {
    
    var activity: Activity?
    
    var view_already_loaded = false // so we don't set buttons twice, the first time
    
    @IBOutlet weak var schedule_button: UIButton!
    @IBOutlet weak var cm_evaluation_button: UIButton!
    @IBOutlet weak var login_button: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        login_button.titleLabel?.adjustsFontSizeToFitWidth = true
        
        if !view_already_loaded {
            set_loggin_button()
            set_evaluate_button()
            set_schedule_button()
        }
        
        schedule_button.titleLabel?.adjustsFontSizeToFitWidth = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if view_already_loaded {
            set_loggin_button()
            set_evaluate_button()
            set_schedule_button()
        }else{
            view_already_loaded = true
        }
    }
    
    func set_schedule_button() {
        
        let activity_has_product = activity!.has_product as Bool
        let activity_is_scheduled = activity!.is_scheduled as Bool
    
        if activity_has_product {
            
            if activity_is_scheduled {
                schedule_button.setTitle("On Your Schedule", for: UIControlState())
                schedule_button.backgroundColor = UIColor(red: 0.75, green: 0.85, blue: 0.75, alpha: 0.8)
                schedule_button.setTitleColor(UIColor.darkGray, for:UIControlState())
            }else{
                schedule_button.setTitle("Ticket Required", for: UIControlState())
                schedule_button.backgroundColor = UIColor(red: 0.8, green: 0.8, blue: 0.84, alpha: 0.8)
                schedule_button.setTitleColor(UIColor.darkGray, for:UIControlState())
            }
            schedule_button.isUserInteractionEnabled = false
            
        }else{
            
            if activity_is_scheduled {
                schedule_button.setTitle("— Schedule", for: UIControlState())
                schedule_button.backgroundColor = UIColor(red: 0.59, green: 0.0, blue: 0.0, alpha: 1.0)
                schedule_button.setTitleColor(UIColor.white, for:UIControlState())
            }else{
                schedule_button.setTitle("+ Schedule", for: UIControlState())
                schedule_button.backgroundColor = UIColor(red: 0.0, green: 0.59, blue: 0.33, alpha: 1.0)
                schedule_button.setTitleColor(UIColor.white, for:UIControlState())
            }
            schedule_button.isUserInteractionEnabled = true
        }
    }
    
    func set_evaluate_button() {
        
        if activity!.hasStarted() {
            // activate button
            cm_evaluation_button.backgroundColor = UIColor(red: 0.0, green: 0.33, blue: 0.59, alpha: 1.0)
            cm_evaluation_button.isUserInteractionEnabled = true
            cm_evaluation_button.setTitleColor(UIColor.white, for:UIControlState())
        } else {
            cm_evaluation_button.backgroundColor = UIColor(red: 0.8, green: 0.8, blue: 0.84, alpha: 0.8)
            cm_evaluation_button.isUserInteractionEnabled = false
            cm_evaluation_button.setTitleColor(UIColor.darkGray, for:UIControlState())
        }
        
        let is_aicp : Bool = User.hasWebGroup("aicp_cm") || User.hasWebGroup("reinstatement_cm")
        let has_cm : Bool = activity!.cm as Double > 0.0
        
        if is_aicp && has_cm {
            cm_evaluation_button.setTitle("Log CM / Evaluate", for:UIControlState())
        }else{
            cm_evaluation_button.setTitle("Evaluate", for:UIControlState())
        }
    }
    
    func set_loggin_button() {
        
        if User.isAuthenticated() {
            login_button.isHidden = true
        }else{
            login_button.isHidden = false
        }
    }
    
    @IBAction func evaluate_activity(_ sender: AnyObject) {
        
        if !Reachability.isConnectedToNetwork() {
            
            custom_alert("No Network Connection", message: "Please try again later.", actions: [])
            
        }else if !User.isAuthenticated() {
            set_loggin_button()
            set_schedule_button()
        }else{
            
            performSegue(withIdentifier: "ActivityEvaluation", sender: self)
            
        }
    }
    
    @IBAction func go_to_login(_ sender: AnyObject) {
        if !User.isAuthenticated() {
            LoginViewController.show(self)
        }else{
            set_loggin_button()
            set_schedule_button()
        }
    }
    
    @IBAction func toggleSchedule(_ sender: AnyObject) {
        
        if !User.isAuthenticated() {
            
            set_loggin_button()
            set_schedule_button()
            
        }else{
            
            let customLoader = startCustomLoading(self.view, title:"Loading", message:"Updating your schedule")
            
            let action = activity!.is_scheduled as Bool ? "remove" : "add"
            
            activity?.schedule_change(appCore.managedContext, activity: activity!, action:action, callback: {(success:Bool) -> Void in
                
                customLoader.removeFromSuperview()
                
                self.set_schedule_button()
                
            })
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ActivityEvaluation" {
            let activityEvaluationViewController = segue.destination as! ActivityEvaluationViewController
            activityEvaluationViewController.activity = self.activity
        }
    }


}
