//
//  CallendarIntegration.swift
//  planning-ios
//
//  Created by Matthew O'Connor on 10/27/16.
//  Copyright © 2016 American Planning Association. All rights reserved.
//

import Foundation
import EventKit
import CoreData

class CalendarIntegration {
    
    //UNCOMMENT if we want this to be singleton singleton - do we want that?
    //static let ical = CalendarIntegration()
    //private init() {}
    
    let eventStore = EKEventStore()
    let userDefaultIdentifier:String = "CalendarIntegrationIdentifierNPC"
    var calendarIdentifier : String?
    var calendar : EKCalendar?
    
    var authorizationStatus:EKAuthorizationStatus {
        get {
            //returns .notDetermined, .authorized, .restricted or .denied
            return EKEventStore.authorizationStatus(for: EKEntityType.event)
        }
    }
    
    func requestAccessToCalendar(forceRequest:Bool = false, callback: @escaping (_ success: Bool) -> Void ) {
        
        if forceRequest || authorizationStatus == .notDetermined {
            eventStore.requestAccess(to: EKEntityType.event, completion: {
                (accessGranted: Bool, error: Error?) in
                
                // accessGranted is true if user has given access
                if accessGranted == true {
                    callback(true)
                } else {
                    callback(false)
                }
            })
        }else {
            callback(authorizationStatus == .authorized)
        }
        
    }
    
    func setCalendar() -> EKCalendar? {
        /* 
            Will try to fetch Calendar matching the istance's calendarIdentifier,
            if cannot find calendar, then create and return new calendar
        */
        
        calendarIdentifier = UserDefaults.standard.string(forKey: userDefaultIdentifier)
        if let existingCalendar = fetchCalendar() {
            calendar = existingCalendar
            return calendar
        }else{
            return createCalendar()
        }
    }
    
    private func createCalendar() -> EKCalendar? {
        /*
            creates a new calendar to use with this instance,
            should only use if calendar does not already exist
         
            currently does not check if calendar already exists for this application
        */
        let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
        newCalendar.title = "NPC 2017"
        let sourcesInEventStore = eventStore.sources
        
        
        let icloudSource = sourcesInEventStore.filter{
            (source: EKSource) -> Bool in
            source.sourceType.rawValue == EKSourceType.calDAV.rawValue && source.title == "iCloud"
        }.first
        
        let localSource = sourcesInEventStore.filter{
            (source: EKSource) -> Bool in
            source.sourceType.rawValue == EKSourceType.local.rawValue
        }.first
        
        
        
        if let icloud = icloudSource {
            // first try icloud because local calendars don't sync if icloud is already set up...
            newCalendar.source = icloud
            print("icloud")
        }else if let local = localSource {
            // ...otherwise use local...after the phone allows icloud calendar, this will be merge into icloud
            newCalendar.source = local
            print("local")
        }else {
            // PROMPT TO SETUP THEIR CALENDAR!!!!!!!!!!!
            print("no source!!")
        }
        
        do {
            try eventStore.saveCalendar(newCalendar, commit: true)
            UserDefaults.standard.set(newCalendar.calendarIdentifier, forKey: userDefaultIdentifier)
            calendarIdentifier = newCalendar.calendarIdentifier
            calendar = newCalendar
            return newCalendar
        } catch {
            print("ERROR creating new calendar")
            return nil
        }
    }
    
    func fetchCalendar() -> EKCalendar? {
        if let calID = calendarIdentifier {
            return eventStore.calendar(withIdentifier:calID)
        }else{
            return nil
        }
        
    }
    
    func syncCalendarWithActivities(_ activities:[Activity], moc:NSManagedObjectContext){
        
        if let eventCalendar = calendar {
            
            // Get all external identifiers for ical
            let calendarIdentifiers = activities.filter({$0.calendar_identifier != nil}).map({$0.calendar_identifier!})
            
            // NOT SURE OF THE BEST WAY TO HANDLE DATE RANGE, we don't want to restrict by date range, but it seems required
            // distantPast ad distantFuture did not seem to work, currently just setting endtime to arbitrary hard coded later date
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let startDate =  dateFormatter.date(from: "2016-01-01") // Date.distantPast
            let endDate =  dateFormatter.date(from: "2030-01-01") // Date.distantFuture
            
            let eventsPredicate = eventStore.predicateForEvents(withStart: startDate!, end: endDate!, calendars: [eventCalendar])
            
            // remove events from calendar that are not in the external identifiers list
            for event in eventStore.events(matching: eventsPredicate).filter({ !calendarIdentifiers.contains($0.eventIdentifier)  }) {
                do {
                    try eventStore.remove(event, span:.thisEvent)
                }catch{
                    print("ERROR: removing event from ical")
                }
            }
            
            // get or create events that are in the schedule
            for activity in activities {
                saveActivity(activity, moc:moc)
            }
            
            // probably not necessary, but just to clean data,
            //   we don't need unscheduled events with calendarIdentifiers
            do {
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Activity")
                let unscheduledPredicate = NSPredicate(format: "is_scheduled == false && calendar_identifier != nil")
                fetchRequest.predicate = unscheduledPredicate
                for activity in try moc.fetch(fetchRequest) as! [Activity]{
                    activity.calendar_identifier = nil
                }
                try moc.save()
            }catch{
                print("ERROR: removing calendarIdentifiers from unscheduled activities")
            }
        
        }
    }
    
    func saveActivity(_ activity:Activity, moc:NSManagedObjectContext) -> EKEvent? {
        
        // safely not assuming calendar exists,
        if let eventCalendar = calendar
        {
            var event:EKEvent?
            if let caledarEventIdentifier = activity.calendar_identifier, let calendarEvent = eventStore.event(withIdentifier:caledarEventIdentifier) {
                event = calendarEvent
            }else{
                event = EKEvent(eventStore: eventStore)
            }
            let e = event!
            
            e.calendar = eventCalendar
            e.title = activity.title
            e.startDate = activity.begin_time!
            e.endDate = activity.end_time!
            e.location = activity.tag_location
            e.timeZone = TimeZone(identifier:appCore.timeZoneName)
            e.url = URL(string: "\(appCore.site_domain)/events/nationalconferenceactivity/\(activity.id)/")
            e.notes = activity.description_string
            
            // Save the calendar using the Event Store instance
            do {
                try eventStore.save(e, span:.thisEvent, commit:true)
                activity.calendar_identifier = e.eventIdentifier
                try moc.save()
                return e
            } catch {
                print("ERROR adding event to ical")
                return nil
            }
        
        } else {
            return nil
        }
    }
    
    func removeActivity(_ activity:Activity, moc:NSManagedObjectContext) -> Bool {
        if let caledarEventIdentifier = activity.calendar_identifier, let calendarEvent = eventStore.event(withIdentifier:caledarEventIdentifier) {
            do {
                try eventStore.remove(calendarEvent, span:.thisEvent, commit:true)
                activity.calendar_identifier = nil
                try moc.save()
                return true
            }catch{
                print("ERROR removing single event from ical")
                return false
            }
        }else{
            return false
        }
    }
}
