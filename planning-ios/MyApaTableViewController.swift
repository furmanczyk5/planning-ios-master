//
//  MyApaTableViewController.swift
//  planning-ios
//
//  Created by Matthew O'Connor on 3/30/15.
//  Copyright (c) 2015 American Planning Association. All rights reserved.
//

import UIKit

class MyApaTableViewController: UITableViewController {
    
    var user : User?
    
    @IBOutlet weak var userIdCell: UITableViewCell!
    @IBOutlet weak var FullNameCell: UITableViewCell!
    @IBOutlet weak var JobTitleCell: UITableViewCell!
    @IBOutlet weak var CompanyCell: UITableViewCell!
    
    @IBOutlet weak var myScheduleCell: UITableViewCell!
    @IBOutlet weak var cmLogCell: UITableViewCell!
    
    @IBOutlet weak var iCalPermissionCell: UITableViewCell!
    @IBOutlet weak var iCalPermissionText: UILabel!
    @IBOutlet weak var iCalPermissionButton: UIButton!
    
    @IBOutlet weak var login_nav_button: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !User.isAuthenticated() {
            self.performSegue(withIdentifier: "login", sender: self)
        }

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        user = User.fetch(appCore.managedContext)
        
        resetTable()
    }
    
    func setContactInfo() {
        
        if User.isAuthenticated()  {
            
            myScheduleCell!.textLabel!.isEnabled = true
            myScheduleCell.isUserInteractionEnabled = true
            
            iCalPermissionCell.isUserInteractionEnabled = true
            iCalPermissionButton.setTitleColor(UIColor(red: 0.00, green: 0.00, blue: 1.00, alpha: 1.0), for: UIControlState.normal)
            if appCore.iCal.authorizationStatus == .authorized {
                iCalPermissionText!.text = "iCal Permission: Yes"
                iCalPermissionText!.textColor = UIColor(red: 0.45, green: 0.75, blue: 0.45, alpha: 1.0)
            }else{
                iCalPermissionText!.text = "iCal Permission: No"
                iCalPermissionText!.textColor = UIColor(red: 1.00, green: 0.00, blue: 0.00, alpha: 1.0)
            }
            
            if User.hasWebGroup("aicp_cm") {
                cmLogCell.isUserInteractionEnabled = true
                cmLogCell!.textLabel!.isEnabled = true
            }else{
                cmLogCell.isUserInteractionEnabled = false
                cmLogCell!.textLabel!.isEnabled = false
            }
            
            userIdCell!.textLabel!.text = User.user_id
            userIdCell!.detailTextLabel!.text = "User ID"
            FullNameCell!.textLabel!.text = user?.full_name ?? ""
            JobTitleCell!.textLabel!.text = user?.job_title ?? ""
            CompanyCell!.textLabel!.text = user?.company ?? ""
        
        }else{
            
            userIdCell!.textLabel!.text = " "
            userIdCell!.detailTextLabel!.text = "Log in to see your My APA, My Schedule, My CM and more."
            FullNameCell!.textLabel!.text = " "
            JobTitleCell!.textLabel!.text = " "
            CompanyCell!.textLabel!.text = " "
            
            myScheduleCell.isUserInteractionEnabled = false
            cmLogCell.isUserInteractionEnabled = false
            
            myScheduleCell!.textLabel!.isEnabled = false
            cmLogCell!.textLabel!.isEnabled = false
            
            iCalPermissionCell.isUserInteractionEnabled = false
            iCalPermissionText!.text = "iCal Permission"
            iCalPermissionText!.textColor = UIColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 1.0)
            iCalPermissionButton.setTitleColor(UIColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 1.0), for: UIControlState.normal)
        
        }
        
    }
    
    func resetTable() {
        
        if User.isAuthenticated() {
            
            var custom_loader : CustomLoadingView?
            
            // should have full name if contact info is on core data
            
            let full_name = user!.full_name as String? ?? ""
            if full_name == "" {
                custom_loader = startCustomLoading(self.navigationController!.view, title: "Loading", message: "Getting user info...")
                
                User.getContactInfo(appCore.managedContext, callback: {(success: Bool) in
                    
                    self.user = User.fetch(appCore.managedContext)
                    
                    self.setContactInfo()
                    
                    if custom_loader != nil {
                        custom_loader?.removeFromSuperview()
                    }
                    
                })
                
            }else{
                self.setContactInfo()
            }
            
            login_nav_button.title = "Log Out"
            
        } else {
            
            self.setContactInfo()
            
            login_nav_button.title = "Log In"
            
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        if section == 0 {
           return 4
        }else{
            return 3
        }
    }
    
    @IBAction func login_logout(_ sender: AnyObject) {
        
        if User.isAuthenticated() {
            var customLoader = startCustomLoading(self.navigationController!.view, message: "Logging Out...")
            User.logout({ (success) -> Void in
                customLoader.removeFromSuperview()
                self.performSegue(withIdentifier: "login", sender: self)
            })
        } else {
            performSegue(withIdentifier: "login", sender: self)
        }
        
    }
    @IBAction func iCalEditPermission(_ sender: Any) {
        let openSettingsUrl = URL(string: UIApplicationOpenSettingsURLString)
        UIApplication.shared.openURL(openSettingsUrl!)
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let segueIdentifier = segue.identifier!
        
        switch segueIdentifier {
        case "cmLog":
            let myApaWebViewController = segue.destination as! MyApaWebViewController
            myApaWebViewController.url = "\(appCore.site_domain)/mobile/cm/log/"
            myApaWebViewController.title = "My CM"
        case "mySchedule":
            let activityTableViewController = segue.destination as! ActivityTableViewController
            activityTableViewController.program_option = ProgramOption(title: "My Schedule", data_source: .myschedule)
            activityTableViewController.title = activityTableViewController.program_option!.title
        case "login":
            break
        default:
            break
        }
    }

}
