//
//  Extensions.swift
//  planning-ios
//
//  Created by Matthew O'Connor on 3/3/15.
//  Copyright (c) 2015 American Planning Association. All rights reserved.
//

import Foundation
import UIKit

extension Date
{
    
    init(dateString:String, timezone:String="UTC") {
        let dateStringFormatter = DateFormatter()
        dateStringFormatter.dateFormat = "yyyy-MM-dd"
        dateStringFormatter.timeZone = TimeZone(identifier:timezone)
        dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
        let d = dateStringFormatter.date(from: dateString)
        self.init(timeInterval:0, since:d!)
    }
    
    func date_time_short_user_friendly(timezone:String="UTC") -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier:timezone)
        dateFormatter.dateFormat = "MMM d, h:mm a"
        return dateFormatter.string(from: self)
    }
}

extension UIViewController {
    
    func custom_alert(_ title:String, message:String, includeDefaultOK:Bool = true, actions: [(title:String, handler:() -> Void )] = [] ) {
        if objc_getClass("UIAlertController") != nil {
            let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
            
            if actions.filter({$0.title == "OK"}).isEmpty && includeDefaultOK {
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            }
                
            for action in actions {
                alert.addAction(UIAlertAction(title: action.title, style: UIAlertActionStyle.default, handler: { (alert: UIAlertAction) in action.handler() } ))
            }
            
            self.present(alert, animated: true, completion: nil)
        }else{
            let alert: UIAlertView = UIAlertView()
            alert.delegate = self
            alert.title = title
            alert.message = message
            alert.addButton(withTitle: "OK")
            
//            for action in actions {
//                alert.addButtonWithTitle(action.title)
//            }
//            
//            // how to add buttons with handlers for iOS7
//            func alertView(View: UIAlertView!, clickedButtonAtIndex buttonIndex: Int){
//                if buttonIndex == 0 {
//                    
//                }else{
//                    actions[buttonIndex - 1].handler()
//                }
//            }
            
            alert.show()
        }
    }
}
