//
//  AppCore.swift
//  planning-ios
//
//  Created by Matthew O'Connor on 2/18/15.
//  Copyright (c) 2015 American Planning Association. All rights reserved.
//

import Foundation
import CoreData
import UIKit
import Alamofire

class AppCore : NSObject {
    
    let managedContext : NSManagedObjectContext
    let timeZoneName : String = "US/Eastern" // location of the conference
    let site_domain : String = "https://www.planning.org"
    
    var attendees : [Attendee] = []
    var iCal : CalendarIntegration = CalendarIntegration()
    var files : WebViewFileIntegration = WebViewFileIntegration()
    var webview_user_id: String?
    
    var base_url : String {
        get {
            return "\(site_domain)/conference/api/0.2"
        }
    }
    
    var urls : [String:String] {
        get {
            return [
                "login"             :"\(base_url)/login/",
                "logout"            :"\(base_url)/logout/",
                "contact"           :"\(base_url)/contact/",
                "activities"        :"\(base_url)/activities/",
                "schedule"          :"\(base_url)/schedule/",
                "schedule_update"   :"\(base_url)/schedule/update/",
                "schedule_add"      :"\(base_url)/schedule/add/",
                "schedule_remove"   :"\(base_url)/schedule/remove/",
                "attendees"         :"\(base_url)/attendees/",
                "auto_login"        :"\(site_domain)/auto_login_via_mobile/"
            ]
        }
    }
    
    override init() {
        let appDelegate :AppDelegate = UIApplication.shared.delegate as! AppDelegate
        managedContext = appDelegate.managedObjectContext
        
//        if User.isAuthenticated() {
//            let user = User.fetch(managedContext)
//            if let fullname = user.full_name {
//                User.getContactInfo(managedContext, callback: <#(success: Bool) -> Void##(success: Bool) -> Void#>)
//            }
//        }
        
        super.init()
    }
        
}
