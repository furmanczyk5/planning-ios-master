//
//  Activity.swift
//  planning-ios
//
//  Created by Matthew O'Connor on 3/17/15.
//  Copyright (c) 2015 American Planning Association. All rights reserved.
//

import Foundation
import CoreData
import Alamofire

//never use "," characters in the string values here
enum OfflineActions:String {
    case ScheduleAdd = "ScheduleAdd"
    case ScheduleRemove = "ScheduleRemove"
    case None = ""
}

class Activity: NSManagedObject {

    @NSManaged var id: String
    @NSManaged var title: String
    @NSManaged var subtitle: String
    @NSManaged var description_string: String
    @NSManaged var code: String
    @NSManaged var cm: NSNumber
    @NSManaged var cm_law: NSNumber
    @NSManaged var cm_ethics: NSNumber
    @NSManaged var begin_time: Date?
    @NSManaged var end_time: Date?
    @NSManaged var is_scheduled: NSNumber
    @NSManaged var has_product: NSNumber
    @NSManaged var details_html: String
    @NSManaged var tags: String
    @NSManaged var tag_location: String
    @NSManaged var speakers: NSSet
    @NSManaged var action_offline: String // don't ever directly set or get this, use actions_offline_enum
    @NSManaged var calendar_identifier: String? // for integrating with ical
    @NSManaged var prices: String? // for listing prices of tickets
    
    var action_offline_enum: OfflineActions {
        get {
            return OfflineActions(rawValue: action_offline) ?? OfflineActions.None
        }
        set(newValue) {
            action_offline = newValue.rawValue
        }
    }
    
    
    // convenience getter/setters
    var solr_id : String {
        get {
            return "CONTENT.\(id)"
        }
        set(newValue) {
            var type_id_array = newValue.components(separatedBy: ".")
            id = type_id_array.count > 1 ? type_id_array[1] : ""
        }
    }
    
    var begin_time_json_string : String {
        get {
            if begin_time != nil {
                let json_date_formatter = DateFormatter()
                json_date_formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                json_date_formatter.timeZone = TimeZone(identifier:"UTC")
                return json_date_formatter.string(from: begin_time!)
            }else{
                return ""
            }
        }
        set(newValue) {
            var setValue : Date?
            if newValue == "" {
                setValue = nil
            }else{
                let fixed_newValue : String = newValue.components(separatedBy: CharacterSet (charactersIn: "TZ")).joined(separator: " ")
                let json_date_formatter = DateFormatter()
                json_date_formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                json_date_formatter.timeZone = TimeZone(identifier:"UTC") // always setting as UTC, bc search results are in UTC
                setValue = json_date_formatter.date(from: fixed_newValue)
            }
            begin_time = setValue
        }
    }
    var end_time_json_string : String {
        get {
            if end_time != nil {
                let json_date_formatter = DateFormatter()
                json_date_formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                json_date_formatter.timeZone = TimeZone(identifier:"UTC")
                return json_date_formatter.string(from: self.end_time!)
            }else{
                return ""
            }
            
        }
        set(newValue) {
            var setValue : Date?
            if newValue == ""{
                setValue = nil
            }else{
                let fixed_newValue : String = newValue.components(separatedBy: CharacterSet (charactersIn: "TZ")).joined(separator: " ")
                let json_date_formatter = DateFormatter()
                json_date_formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                json_date_formatter.timeZone = TimeZone(identifier:"UTC") // always setting as UTC, bc search results are in UTC
                setValue = json_date_formatter.date(from: fixed_newValue)
            }
            end_time = setValue
        }
    }
    var date_string : String? {
        get {
            //uses the begin date always
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEEE, MMMM d, yyyy"
            dateFormatter.timeZone = TimeZone(identifier:appCore.timeZoneName)
            if self.begin_time != nil {
                return dateFormatter.string(from: self.begin_time!)
            }else{
                return nil
            }
        }
    }
    var time_string : String {
        get {
            var formatted_time = ""
            let dateFormatter = DateFormatter()
            dateFormatter.timeZone = TimeZone(identifier:appCore.timeZoneName)
            if is_single_day {
                dateFormatter.dateFormat = "h:mm a"
            }else{
                dateFormatter.dateFormat = "MMM d, h:mm a"
            }
            
            if self.begin_time != nil {
                formatted_time += dateFormatter.string(from: self.begin_time!)
                if self.end_time != nil {
                    formatted_time += " - "
                    formatted_time += dateFormatter.string(from: self.end_time!)
                }
            }
            
            return formatted_time
        }
    }
    var is_single_day : Bool {
        get{
            if begin_time != nil && end_time != nil{
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                dateFormatter.timeZone = TimeZone(identifier:appCore.timeZoneName)
                let begin_string = dateFormatter.string(from: self.begin_time!)
                let end_string = dateFormatter.string(from: self.end_time!)
                return begin_string == end_string
            }else{
                return true
            }
        }
    }
    var price_list : [(name:String, price:String)] {
        get {
            if prices != nil && prices != "" {
                return prices!.components(separatedBy:"|;|").map({ $0.components(separatedBy:"|@|") }).map( {(name:$0[1], price:$0[0])} )
            }else{
                return []
            }
            
        }
        set(newValue) {
            prices = newValue.map({"\($0.price)|@|\($0.name)"}).joined(separator:"|;|")
        }
    }
    
    func hasStarted() -> Bool {
        let calendar = Calendar.current
        var comps = DateComponents()
        comps.minute = 0
        let date_cutoff = (calendar as NSCalendar).date(byAdding: comps, to: Date(), options: NSCalendar.Options())
        
        if begin_time == nil || begin_time?.compare(date_cutoff!) == ComparisonResult.orderedDescending {
            return false
        }else{
            return true
        }
    }
    
    // THIS SHOULD NEVER FAIL! IF REQUEST FAILS, JUST ADD THE ACTION TO THE OFFLINE_ACTIONS
    func schedule_change(_ moc:NSManagedObjectContext, activity:Activity, action:String, callback:@escaping (_ success:Bool)->Void){
        
        let schedule_update_params:[String:AnyObject]
        if action == "add" {
            schedule_update_params = ["add": activity.id as AnyObject]
        }else {
            schedule_update_params = ["remove": activity.id as AnyObject]
        }
        
        User.authenticatedRequest(.post, url: appCore.urls["schedule_update"]!, params: schedule_update_params) {
            response -> () in
            
            switch response.result {
                
                case .success(let data):
                    let json = JSON(data)

                    print(json)
                    
                    let successful = json["success"].boolValue
                    //let error_text = json["result"]["error"].string ?? nil
                    
                    if !successful {
                        activity.action_offline_enum = action == "add" ? .ScheduleAdd : .ScheduleRemove
                    }
                    
                case .failure(let error):
                    activity.action_offline_enum = action == "add" ? .ScheduleAdd : .ScheduleRemove
                    print("Request failed with error: \(error)")
            }
            
            
            //////////
            
            if action == "add" {
                activity.is_scheduled = true
            }else{
                activity.is_scheduled = false
            }
            
            do {
                try moc.save()
            } catch{}
            
            // sync ical if have permission
            appCore.iCal.requestAccessToCalendar(
                callback: {(_ authorized:Bool) -> Void in
                    if authorized {
                        // only create and sync calendar if calendar not already set
                        let scheduled_activities = Activity.myschedule()
                        appCore.iCal.setCalendar()
                        appCore.iCal.syncCalendarWithActivities(scheduled_activities, moc: appCore.managedContext)
                    }
            })
            
            callback(true)
        }
    }
    
    
    func speakers_update(_ moc:NSManagedObjectContext, speaker_strings:[String]) {
        
        let activity_speakers = self.mutableSetValue(forKey: "speakers");
        activity_speakers.removeAllObjects()                            // first remove all speakers from activity
    
        for speaker_string in speaker_strings {
            let speaker_id_title = speaker_string.components(separatedBy: "|")
            let speaker_id = speaker_id_title[0]
            let speaker_title = speaker_id_title[1]
            let speaker = Speaker.createOrUpdateInManagedObjectContext(moc, id: speaker_id, title: speaker_title)
            activity_speakers.add(speaker)
        }
    }
    
    
    ///////////////////////////////////////////
    // CLASS METHODS                         //
    // methods for the program and schedule  //
    ///////////////////////////////////////////
    
    
    // return all activities
    class func all() -> [Activity] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Activity")
        let sortDescriptor_beginTime = NSSortDescriptor(key: "begin_time", ascending: true)
        let sortDesctiptor_endTime = NSSortDescriptor(key: "end_time", ascending: true)
        let sortDescriptors = [sortDescriptor_beginTime, sortDesctiptor_endTime]
        fetchRequest.sortDescriptors = sortDescriptors
        return (try? appCore.managedContext.fetch(fetchRequest)) as? [Activity] ?? []
    }
    
    //return myschedule
    class func myschedule() -> [Activity] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Activity")
        
        let sortDescriptor_beginTime = NSSortDescriptor(key: "begin_time", ascending: true)
        let sortDesctiptor_endTime = NSSortDescriptor(key: "end_time", ascending: true)
        let sortDescriptors = [sortDescriptor_beginTime, sortDesctiptor_endTime]
        fetchRequest.sortDescriptors = sortDescriptors
        
        let predicate = NSPredicate(format: "is_scheduled == %@", true as CVarArg)
        fetchRequest.predicate = predicate
        
        return (try? appCore.managedContext.fetch(fetchRequest)) as? [Activity] ?? []
    }
    
    
    // will update both Program and MySchedule from server
    class func pullAll(_ moc:NSManagedObjectContext, callback: @escaping (_ success: Bool) -> Void) {
        
        User.authenticatedRequest(.get, url: appCore.urls["activities"]!, postCompleted: {
            response -> () in
            
            switch response.result {
                
            case .success(let data):
                let json = JSON(data)
                
                let schedule_id_list = json["conference_schedule_results"].arrayValue.map{ $0.stringValue }
                var activity_id_list : [String] = []
                
                for (_, JSONactivity) in json["results"]["response"]["docs"] {
                    
                    // SAVE NEW RECORD TO CORE DATA
                    // STILL NEED TAGS AND SPEAKERS
                    let activity = Activity.createOrUpdateInManagedObjectContext(moc,
                        solr_id:                JSONactivity["id"].string ?? "",
                        title:                  JSONactivity["title"].string ?? "",
                        subtitle:               JSONactivity["subtitle"].string ?? "",
                        description_string:     JSONactivity["description"].string ?? "",
                        code:                   JSONactivity["code"].string ?? "",
                        cm:                     JSONactivity["cm_approved"].double ?? 0.0,
                        cm_law:                 JSONactivity["cm_law_approved"].double ?? 0.0,
                        cm_ethics:              JSONactivity["cm_ethics_approved"].double ?? 0.0,
                        has_product:            JSONactivity["has_product"].bool ?? false,
                        begin_time_json_string: JSONactivity["begin_time"].string ?? "",
                        end_time_json_string:   JSONactivity["end_time"].string ?? "",
                        prices:                 JSONactivity["prices"].arrayValue.map { $0.stringValue } ?? [],
                        tags:                   JSONactivity["tags"].arrayValue.map { $0.stringValue } ?? [],
                        tag_location:           JSONactivity["tags_ROOM"].arrayValue.map { $0.stringValue } ?? []
                    )
                    
                    activity_id_list.append(activity.id)
                    
                    if schedule_id_list.contains(activity.solr_id) {
                        activity.is_scheduled = true
                    }else{
                        activity.is_scheduled = false
                    }
                    
                    //NEED TO FIGURE OUT HOW WE WANT TO ORGANIZE SPEAKERS, ACTIVITIES, AND EVALUATIONS
                    let speakers = JSONactivity["contact_roles_SPEAKER"].arrayValue.map { $0.stringValue } ?? []
                    activity.speakers_update(moc, speaker_strings:speakers)
                }
                
                let pull_all_callback = callback
                self.queueOfflineActions(moc, callback:{(success:Bool) in
                    if success == true{
                        self.clean_by_ids(moc, keeper_ids:activity_id_list)     // Delete Activities that are no longer in the program
                        Speaker.clean(moc)                                      // Delete speakers on client side that are no longer attached to any activity
                        do {
                            try moc.save()
                        } catch _ {
                        }                                           // should nil be changed to error?
                        
                        // sync ical if have permission
                        appCore.iCal.requestAccessToCalendar(
                            callback: {(_ authorized:Bool) -> Void in
                                if authorized {
                                    // only create and sync calendar if calendar not already set
                                    let scheduled_activities = myschedule()
                                    appCore.iCal.setCalendar()
                                    appCore.iCal.syncCalendarWithActivities(scheduled_activities, moc: appCore.managedContext)
                                }
                        })
                        
                        pull_all_callback(true)
                    }else{
                        pull_all_callback(false)
                    }
                })
                
            case .failure(let error):
                callback(false)
            }
        })
    }
    
    // For only getting the user's schedule
    class func pullMyschedule(_ moc:NSManagedObjectContext, callback: @escaping (_ success: Bool) -> Void) {
        
        User.authenticatedRequest(.get, url: appCore.urls["schedule"]!, postCompleted: {
            (response) -> () in
            
            switch response.result {
                
            case .success(let data):
                let json = JSON(data)
                
                print(json)
                
                if json["is_authenticated"].boolValue {
                    
                    let schedule_id_list = json["schedule_ids"].arrayValue.map{ $0.intValue } ?? [Int]()
                    self.clearSchedule(moc)
                    
                    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Activity")
                    fetchRequest.predicate = NSPredicate(format: "ANY id IN %@", schedule_id_list)
                    let fetchResults = (try? moc.fetch(fetchRequest)) as? [Activity]
                    for result in fetchResults! {
                        result.is_scheduled = true
                    }
                    
                    let pull_myschedule_callback = callback
                    self.queueOfflineActions(moc, callback:{(success:Bool) in
                        if success == true{
                            pull_myschedule_callback(true)
                        }else{
                            pull_myschedule_callback(false)
                        }
                        do {
                            try moc.save()
                            
                            // sync ical if have permission
                            appCore.iCal.requestAccessToCalendar(
                                callback: {(_ authorized:Bool) -> Void in
                                    if authorized {
                                        // only create and sync calendar if calendar not already set
                                        let scheduled_activities = myschedule()
                                        appCore.iCal.setCalendar()
                                        appCore.iCal.syncCalendarWithActivities(scheduled_activities, moc: appCore.managedContext)
                                    }
                            })
                            
                        } catch _ {
                        }
                    })
                }
            
                callback(json["success"].boolValue)
                
            case .failure(let error):
                
                callback(false)
                print(error)
                
            }
        })
    }
    
    // FOR SAVING FROM SOLR RESULTS
    // Data not actually saved until NSManagedObjectContext is saved()
    class func createOrUpdateInManagedObjectContext(_ moc:NSManagedObjectContext, solr_id:String, title:String, subtitle:String, description_string:String, code:String, cm:Double, cm_law:Double, cm_ethics:Double, has_product:Bool, begin_time_json_string:String, end_time_json_string:String, prices:[String], tags:[String], tag_location:[String]) -> Activity {
        
        let type_id_array = solr_id.components(separatedBy: ".")
        let item_id = type_id_array.count > 1 ? type_id_array[1] : ""
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Activity")
        let predicate = NSPredicate(format: "id == %@", item_id)
        fetchRequest.predicate = predicate
        
        var fetchResults = (try? moc.fetch(fetchRequest)) as? [Activity]
        
        var item : Activity
        if fetchResults != nil && fetchResults!.count > 0 {
            item = fetchResults![0]
        } else {
            item = NSEntityDescription.insertNewObject(forEntityName: "Activity", into: moc) as! Activity
            item.action_offline_enum = OfflineActions.None
        }
        
        item.solr_id = solr_id
        item.title = title
        item.subtitle = subtitle
        item.description_string = description_string
        item.code = code
        item.cm = NSNumber(value: cm)
        item.cm_law = NSNumber(value: cm_law)
        item.cm_ethics = NSNumber(value: cm_ethics)
        item.has_product = has_product as NSNumber
        item.begin_time_json_string = begin_time_json_string
        item.end_time_json_string = end_time_json_string
        item.price_list = prices.map({ $0.components(separatedBy:"|@|") }).map( {(name:$0[1], price:$0[0])} )
        
        let tag_string = tags.joined(separator: ",")
        item.tags = "\(tag_string)"
        
        item.tag_location = tag_location.isEmpty ? "" : tag_location[0].components(separatedBy: ".")[2]

        
        return item
    }
    
    
    // Submits actions to Django and resets all offline actions to ".None" if there is an online connection
    class func queueOfflineActions(_ moc:NSManagedObjectContext, callback:@escaping (_ success:Bool)->Void) {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Activity")
        let predicate = NSPredicate(format: "action_offline != %@", OfflineActions.None.rawValue)
        fetchRequest.predicate = predicate
        
        let fetchResults = (try? moc.fetch(fetchRequest)) as? [Activity]
        
        var add_schedule_array = [String]()
        var remove_schedule_array = [String]()
        
        for result in fetchResults! {
            
            switch(result.action_offline_enum){
            case .ScheduleAdd:
                add_schedule_array.append(result.id)
                result.is_scheduled = true // need to make sure that this wasn't changed from django side then
            case .ScheduleRemove:
                remove_schedule_array.append(result.id)
                result.is_scheduled = false // need to make sure that this wasn't changed from django side then
            default:
                break
            }
            
        }
        
        let add_schedule_string = add_schedule_array.joined(separator: ",")
        let remove_schedule_string = remove_schedule_array.joined(separator: ",")
        
        if !User.isAuthenticated() {
            // YOU ARE NOT LOGGED IN
            print("NOT AUTHENTICATED")
            callback(true)
        }else if add_schedule_array.isEmpty && remove_schedule_array.isEmpty {
            // NOTHING TO COMMIT
            print("NOTHING TO ADD")
            callback(true)
        }else if !Reachability.isConnectedToNetwork() {
            // YOU ARE NOT ONLINE
            print("NOT ONLINE")
            callback(false)
        }else{
            User.authenticatedRequest(.post, url: appCore.urls["schedule_update"]!, params: ["add":add_schedule_string as AnyObject,"remove":remove_schedule_string as AnyObject]) { (response) -> () in
                
                switch response.result {
                    
                case .success(let data):
                    let json = JSON(data)
                    
                    print(json["success"].boolValue)
                    
                    if json["success"].boolValue {
                        self.clearOfflineActions(moc)
                        
                        callback(true)
                    }else{
                        callback(false)
                    }

                case .failure(let error):
                    
                    callback(false)
                    print(error)
                    
                }

            }

        }
    }
    
    // clears the schedule only on the client side, useful when logging out
    class func clearSchedule(_ moc:NSManagedObjectContext) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Activity")
        let fetchResults = (try? moc.fetch(fetchRequest)) as? [Activity]
        for result in fetchResults! {
            result.is_scheduled = false
        }
        do {
            try moc.save()
        } catch _ {
        }
    }
    
    // clears all pending Offline actions on client side
    class func clearOfflineActions(_ moc:NSManagedObjectContext) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Activity")
        let fetchResults = (try? moc.fetch(fetchRequest)) as? [Activity]
        for result in fetchResults! {
            result.action_offline = OfflineActions.None.rawValue
        }
        do {
            try moc.save()
        } catch _ {
        }
    }
    
    //only keep the Activities with IDs that are passed to keeper_ids
    class func clean_by_ids(_ moc:NSManagedObjectContext, keeper_ids: [String]){
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Activity")
        let fetchResults = (try? moc.fetch(fetchRequest)) as? [Activity]
        
        for result in fetchResults! {
            if !keeper_ids.contains(result.id) {
                moc.delete(result)
            }
        }
    }
    
}






