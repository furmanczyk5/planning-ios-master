//
//  NPCInfoOptionsTableViewController.swift
//  planning-ios
//
//  Created by Matthew O'Connor on 3/27/15.
//  Copyright (c) 2015 American Planning Association. All rights reserved.
//

import UIKit

class NPCInfoOptionsTableViewController: UITableViewController  {
    
    @IBOutlet weak var search_attendee_cell: UITableViewCell!
    
    var urlForIndex : [[(title:String, type:String, value:String, segue:String?, network_required:Bool)]] {
        get {
            return [
                [
                    (
                        title:"Wifi Sponsor",
                        type:"web_ext",
                        value:"http://www.aecom.com/",
                        segue:nil,
                        network_required:false
                    )
                ],
                [
                    (   title:"General Info",
                        type:"web",
                        value:"\(appCore.site_domain)/mobile/conference/app/generalinfo/",
                        segue:"NPCInfoWebview",
                        network_required:true
                    ),
                    (   title:"#NPC17 on Social Media",
                        type:"web",
                        value:"\(appCore.site_domain)/mobile/conference/app/socialmedia/",
                        segue:"NPCInfoWebview",
                        network_required:true
                    ),
                    (   title:"Conference Maps",
                        type:"code",
                        value:"MAPS",
                        segue:"ListMaps",
                        network_required:false
                    ),
                    (   title:"Planning Expo",
                        type:"web",
                        value:"\(appCore.site_domain)/mobile/conference/app/planningexpo/",
                        segue:"NPCInfoWebview",
                        network_required:true
                    ),
                    (   title:"Tech Zone",
                        type:"web",
                        value:"\(appCore.site_domain)/mobile/conference/app/techzone/",
                        segue:"NPCInfoWebview",
                        network_required:true
                    ),
                    (   title:"Career Zone",
                        type:"web",
                        value:"\(appCore.site_domain)/mobile/conference/app/careerzone/",
                        segue:"NPCInfoWebview",
                        network_required:true
                    ),
                    (   title:"APA Foundation",
                        type:"web_ext_auth",
                        value:"\(appCore.site_domain)/foundation/",
                        segue:"NPCInfoWebview",
                        network_required:true
                    ),
                    (   title:"NYC Info",
                        type:"web",
                        value:"\(appCore.site_domain)/mobile/conference/app/info/",
                        segue:"NPCInfoWebview",
                        network_required:true
                    ),
                    (   title:"Planners Guide to NYC",
                        type:"web",
                        value:"\(appCore.site_domain)/mobile/conference/app/guide/",
                        segue:"NPCInfoWebview",
                        network_required:true
                    ),
                    (   title:"Travel & Hotel",
                        type:"web",
                        value:"\(appCore.site_domain)/mobile/conference/app/travel/",
                        segue:"NPCInfoWebview",
                        network_required:true
                    ),
                    (   title:"Search Attendees",
                        type:"code",
                        value:"SEARCH_ATTENDEES",
                        segue:"SearchAttendees",
                        network_required:appCore.attendees.isEmpty
                    ),
                    (   title:"Sponsors",
                        type:"web",
                        value:"\(appCore.site_domain)/mobile/conference/app/sponsors/",
                        segue:"NPCInfoWebview",
                        network_required:true
                    ),
                    (   title:"APA Leadership",
                        type:"web_ext_auth",
                        value:"\(appCore.site_domain)/leadership/",
                        segue:"NPCInfoWebview",
                        network_required:true
                    )
                ]
            ]
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if User.hasWebGroup("17CONF") {
            search_attendee_cell.textLabel!.isEnabled = true
            search_attendee_cell.isUserInteractionEnabled = true
        }else{
            search_attendee_cell.textLabel!.isEnabled = false
            search_attendee_cell.isUserInteractionEnabled = false
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }else{
            return 13
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)  {
        
        let indexPathObject = urlForIndex[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).row]
        
        if indexPathObject.type == "web_ext" {
            // take to external browser (outside the app), no special authenticateion
            UIApplication.shared.openURL( URL(string: indexPathObject.value)! )
        }else if indexPathObject.type == "web_ext_auth" {
            // take to external browser (outside the app), authenticate through APA server
            let requestUrl = URL(string: User.getAutoLoginUrl(url: "\(indexPathObject.value)"))
            UIApplication.shared.openURL(requestUrl!)
        }else if let segueIdentifier = indexPathObject.segue {
            if !Reachability.isConnectedToNetwork() && indexPathObject.network_required {
                custom_alert("No Network Connection", message: "Please try again later.", actions: [])
                self.tableView.deselectRow(at: indexPath, animated: true)
            }else{
                self.performSegue(withIdentifier: segueIdentifier, sender: tableView)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if indexPath.section == 0 {
            return tableView.frame.size.width / 3 // hardcoded aspect ratio :'(
        }else{
            return UITableViewAutomaticDimension
        }
    }


    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "NPCInfoWebview" {
            
            let destinationViewController = segue.destination as! NPCInfoWebviewViewController
            let sender_uitableview = sender as! UITableView
            let indexPath = sender_uitableview.indexPathForSelectedRow
            let indexPathObject = urlForIndex[(indexPath! as NSIndexPath).section][(indexPath! as NSIndexPath).row]
            
            if indexPathObject.type == "file" {
                destinationViewController.file = indexPathObject.value
            }else{
                destinationViewController.url = indexPathObject.value + "?auth_user_id=\(User.user_id ?? "")&auth_token=\(User.token ?? "")&auth_login=true&mobile_app=true"
            }
            
            destinationViewController.title = sender_uitableview.cellForRow(at: indexPath!)!.textLabel!.text
            
        }else if segue.identifier == "SearchAttendees" {
            //nothing to do
        }else if segue.identifier == "ListMaps"{
            //nothing to do
        }
    }


}
