//
//  apa.swift
//  planning-ios
//
//  Created by Matthew O'Connor on 4/2/15.
//  Copyright (c) 2015 American Planning Association. All rights reserved.
//

import Foundation
import CoreData
import Alamofire

class User: NSManagedObject {

    @NSManaged var id: String!
    @NSManaged var web_groups: String?
    @NSManaged var company: String?
    @NSManaged var first_name: String?
    @NSManaged var last_name: String?
    @NSManaged var job_title: String?
    @NSManaged var email: String?
    @NSManaged var full_name: String?
    
    var web_groups_array : [String] {
        get {
            return web_groups?.components(separatedBy: ",") as [String]? ?? []
        }
    }
    
    class var user_id : String? {
        get {
            let loaded_user_id = KeychainService.load("user_id")
            if loaded_user_id != nil {
              return NSString(data:loaded_user_id!, encoding: String.Encoding.utf8.rawValue) as? String
            }else{
                KeychainService.clear()
                return nil
            }
        }
    }
    class var token : NSString? {
        get{
            let loaded_token = KeychainService.load("token")
            if loaded_token != nil {
                return NSString(data:loaded_token!, encoding: String.Encoding.utf8.rawValue)
            }else{
                KeychainService.clear()
                return nil
            }
        }
    }
    
    class func hasWebGroup(_ webgroup:String) -> Bool {
        let user = fetch(appCore.managedContext)
        return user.web_groups_array.contains(webgroup)
    }
    
    class func fetch(_ moc: NSManagedObjectContext) -> User {

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "User")
        var fetchResults = (try? moc.fetch(fetchRequest)) as? [User]
        
        if fetchResults != nil && fetchResults!.count == 1 {
            return fetchResults![0]
        }else{
            for result in fetchResults! {
                moc.delete(result)
            }
            
            let new_user = createInManagedObjectContext(moc)
            do {
                try moc.save()
            } catch _ {
            }
            return new_user
        }
    
    }
    
    class func createInManagedObjectContext(_ moc:NSManagedObjectContext) -> User {
        
        let item : User = NSEntityDescription.insertNewObject(forEntityName: "User", into: moc) as! User
        
        item.id = (user_id ?? "") as String               //from keychain

        return item
    }
    
    
    class func isAuthenticated() -> Bool {
        
        if user_id != nil && token != nil{
            return true
        }else{
            return false
        }
    }
    
    class func login(_ username: String, password: String, callback: @escaping (_ success: Bool) -> Void) -> Bool {
        
        let params_dict = ["username": username, "password":password]
        let moc = appCore.managedContext
        
        let user_instance = fetch(moc)
        
        request(appCore.urls["login"]!, method:.post, parameters: params_dict, encoding: URLEncoding.default)
            .responseJSON {
                (response) in
                
                switch response.result {
                    
                case .success(let data):
                    let json = JSON(data)
                    
                    if json["success"].boolValue {
                        
                        if let user_id_string = json["data"]["user_id"].string {
                            user_instance.id = user_id_string as String
                            KeychainService.save("user_id",data: user_id_string.data(using: String.Encoding.utf8)!)
                        }
                        
                        if let token_string = json["data"]["token"].string  {
                            KeychainService.save("token",data: token_string.data(using: String.Encoding.utf8)!)
                        }
                        
                        let other_callback = callback
                        User.getContactInfo(moc, callback: {(success:Bool) in
                            Activity.pullMyschedule(moc, callback: other_callback)
                        })
                        
                    }else{
                        callback(false)
                    }
                
                case .failure(let error):
                    callback(false)
                    print("Request failed with error: \(error)")
                }
                
        }
        
        return true
    }
    
    class func logout(_ callback: (_ success: Bool) -> Void = {(success: Bool) in}) -> Bool {
        
        let moc = appCore.managedContext
        
        if let user_id = user_id {
            
            
            if Reachability.isConnectedToNetwork() {
                //should trigger offline actions
                Activity.queueOfflineActions(moc, callback: { (success) -> Void in
                    
                    request(appCore.urls["logout"]!, method:.post, parameters: ["user_id": user_id], encoding: URLEncoding.default)
                    
                    Activity.clearOfflineActions(moc)
                    Activity.clearSchedule(moc)
                    
                    let user_instance = self.fetch(moc)
                    moc.delete(user_instance)
                    do {
                        try moc.save()
                    } catch _ {
                    }
                    
                    appCore.attendees = []
                    KeychainService.clear()
                    
                })

            }else{
                Activity.clearOfflineActions(moc)
                Activity.clearSchedule(moc)
                
                let user_instance = self.fetch(moc)
                moc.delete(user_instance)
                do {
                    try moc.save()
                } catch _ {
                }
                
                appCore.attendees = []
                KeychainService.clear()
            }
            
            callback(true)
            
        }
        
        appCore.webview_user_id = nil
    
        return true
    }
    
    
    // adds extra authentication parameters to the post, use this when something requires the user to be logged in
    class func authenticatedRequest(_ method:HTTPMethod, url: String, params : Dictionary<String, AnyObject> = Dictionary<String, AnyObject>(), postCompleted : @escaping (_ response: DataResponse<Any>) -> ()) {
        
        var authenticated_params: Dictionary<String, AnyObject> = params
        
        if isAuthenticated() {
            
            authenticated_params["auth_user_id"] = self.user_id! as NSString
            authenticated_params["auth_token"] = self.token! as NSString
            
        }
        
        request(url, method:method, parameters: authenticated_params, encoding: URLEncoding.default)
            .responseJSON { response in
                
                switch response.result {
                    
                    case .success(let data):
                        let json = JSON(data)
                    
                        if let action = json["action"].string {
                            if action == "LOGOUT" {
                                self.logout()
                            }
                        }
                    
                    case .failure(let error):
                        print("Request failed with error: \(error)")
                }
                
                postCompleted(response)
            }
        
    }
    
    class func getAutoLoginUrl(url:String) -> String {
        
        let user_id = User.user_id ?? ""
        let auth_token = User.token ?? ""
        
        var requestUrl : String? = nil
        
        if User.isAuthenticated() {
            let authQuery = "auth_user_id=\(user_id)&auth_token=\(auth_token)&auth_login=true"
            requestUrl = "\(appCore.urls["auto_login"]!)?\(authQuery)&next=\(url)"
        }else{
            requestUrl = "\(appCore.urls["auto_login"]!)?&auth_login=true&next=\(url)"
        }
    
        return requestUrl!
    }
    
    
    class func getContactInfo(_ moc:NSManagedObjectContext, callback: @escaping (_ success: Bool) -> Void) {
        
        let contactParams = Dictionary<String, AnyObject>()
        
        // fetch user from db
        let user_instance : User = fetch(moc)
        
        User.authenticatedRequest(.get, url: appCore.urls["contact"]!, params: contactParams, postCompleted: {
            (response) in
            
            switch response.result {
                
                case .success(let data):
                    let json = JSON(data)
                    let contact_info = json["contact"]
                    
                    user_instance.first_name = contact_info["fields"]["first_name"].string ?? ""
                    user_instance.last_name  = contact_info["fields"]["last_name"].string ?? ""
                    user_instance.full_name  = contact_info["fields"]["title"].string ?? ""
                    user_instance.job_title  = contact_info["fields"]["job_title"].string ?? ""
                    user_instance.company    = contact_info["fields"]["company"].string ?? ""
                    user_instance.email      = contact_info["fields"]["email"].string ?? ""
  
                    let webgroups_array = contact_info["web_groups"].arrayObject as? [String] ?? []
                    user_instance.web_groups = webgroups_array.joined(separator: ",")
                    
                    do{
                        try moc.save()
                    } catch {}

                    callback(true)
                
                case .failure(let error):

                    callback(false)
                    print(error)
            
            }
        })
    }
        
}
