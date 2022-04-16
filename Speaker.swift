//
//  Speaker.swift
//  planning-ios
//
//  Created by Matthew O'Connor on 3/17/15.
//  Copyright (c) 2015 American Planning Association. All rights reserved.
//

import Foundation
import CoreData

class Speaker: NSManagedObject {

    @NSManaged var title: String
    @NSManaged var id: String
    @NSManaged var bio: String
    @NSManaged var company: String
    @NSManaged var job_title: String
    @NSManaged var activities: NSSet
    
    class func createOrUpdateInManagedObjectContext(_ moc:NSManagedObjectContext, id:String, title:String) -> Speaker {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Speaker")
        let predicate = NSPredicate(format: "id == %@", id) // title is the only information that we are actually pulling from solr right now
        fetchRequest.predicate = predicate
        
        var fetchResults = (try? moc.fetch(fetchRequest)) as? [Speaker]
        
        var item : Speaker
        if fetchResults != nil && fetchResults!.count > 0 {
            item = fetchResults![0]
        } else {
            item = NSEntityDescription.insertNewObject(forEntityName: "Speaker", into: moc) as! Speaker
        }
        
        item.id = id
        item.title = title
        
        return item
    }
    
    // remove speakers that are no longer attached to any Activity
    class func clean(_ moc:NSManagedObjectContext) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Speaker")
        let fetchResults = (try? moc.fetch(fetchRequest)) as? [Speaker]
        
        let results_to_delete = fetchResults!.filter({$0.activities.count == 0}) // is this right way to check if NSSet is empty
        
        for result in results_to_delete {
            moc.delete(result)
        }
        
        // SHOULD WE SAVE HERE? MAYBE NOT BECAUSE WE ALWAYS SAVE BEFORE THE APP CLOSES
    }
    
    

}
