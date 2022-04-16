//
//  Content.swift
//  planning-ios
//
//  Created by Matthew O'Connor on 3/27/15.
//  Copyright (c) 2015 American Planning Association. All rights reserved.
//

import Foundation
import Alamofire

class Content {
    
    let master_id : String
    let title : String
    let text : String
    
    init(master_id:String, title:String, text:String) {
        self.master_id = master_id
        self.title = title
        self.text = text
    }
    
    class func getContent(_ master_id:String, callback:@escaping (_ success:Bool, _ content:Content?)->Void) {
        
        User.authenticatedRequest(.get, url: "\(appCore.site_domain)/content/\(master_id)/json/", params: ["textformat":"text" as AnyObject]) {
            (response) -> () in
            
            switch response.result {
                
            case .success(let data):
                let json = JSON(data)
                
                let content = Content(
                    master_id:  json["content"]["master"].string  ?? "",
                    title:      json["content"]["title"].string  ?? "",
                    text:       json["content"]["text"].string ?? ""
                )
                
                callback(true, content)

                
            case .failure(let error):
                
                callback(false, nil)
                print(error)
                
            }
            
        }
        
    }
    
}
