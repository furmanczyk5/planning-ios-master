//
//  Attendee.swift
//  planning-ios
//
//  Created by Matthew O'Connor on 4/1/15.
//  Copyright (c) 2015 American Planning Association. All rights reserved.
//

import Foundation
import Alamofire

class Attendee {
    let title : String
    let lastname : String
    let company : String
    let city : String
    let state : String
    let email : String
    let phone : String
    
    init(title:String, lastname:String, company:String, city:String, state:String, email:String, phone:String){
        self.title = title
        self.lastname = lastname
        self.company = company
        self.city = city
        self.state = state
        self.email = email
        self.phone = phone
    }
    
    class func pullAll(_ callback:@escaping (_ success:Bool, _ error_message:String?) -> Void) {
        
        if !User.isAuthenticated() {
            callback(false, "You are not authorized to search conference attendees")
        }else if !Reachability.isConnectedToNetwork() {
            callback(false, "No network connection. Please try again later.")
        }else{
            
            User.authenticatedRequest(.get, url: appCore.urls["attendees"]!, postCompleted: { (response) -> () in
                
                switch response.result {
                    case .success(let data):
                        let json = JSON(data)
                    
                        var attendee_list = [Attendee]()
                        
                        for (_, attendee) in json["data"] {
                            
                            let attendee = Attendee(
                                title:      attendee["title"].string ?? "",
                                lastname:   attendee["last_name"].string ?? " ",
                                company:    attendee["company"].string ?? "",
                                city:       attendee["city"].string ?? "",
                                state:      attendee["state"].string ?? "",
                                email:      attendee["email"].string ?? "",
                                phone:      attendee["phone"].string ?? ""
                            )
                            
                            attendee_list.append(attendee)
                            
                        }
                        
                        // already sorted
                        appCore.attendees = attendee_list
                        
                        callback(true, nil)
                    
                    case .failure(let error):
                        
                        callback(false, "Error retrieving data from server")
                        print(error)
                }
                
            })
            
        }
        
    }
}
