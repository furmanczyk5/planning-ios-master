//
//  AttendeeSearchTableViewController.swift
//  planning-ios
//
//  Created by Matthew O'Connor on 4/1/15.
//  Copyright (c) 2015 American Planning Association. All rights reserved.
//

import UIKit

class AttendeeSearchTableViewController: UITableViewController, UISearchBarDelegate, UISearchDisplayDelegate {
    
    var attendees = [[Attendee]]()
    var filtered_attendees = [[Attendee]]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(AttendeeSearchTableViewController.refresh), for: UIControlEvents.valueChanged)
        self.refreshControl = refreshControl
        
        if appCore.attendees.isEmpty {
            refresh()
        }else{
            setAttendees()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func refreshAction(_ sender: AnyObject) {
        refresh()
    }
    
    func refresh() {
        
        let customLoader = startCustomLoading(self.navigationController!.view, title: "Loading", message: "Getting Conference Attendee List...")
        Attendee.pullAll { (success, error_message) -> Void in
            if success {
                self.setAttendees()
            }else{
                self.custom_alert("Request Failed", message: error_message!, actions: [])
            }
            customLoader.removeFromSuperview()
            self.refreshControl?.endRefreshing()
        }
    }
    
    func setAttendees() {
        self.attendees = separate_list(appCore.attendees)
        self.tableView.reloadData()
    }
    
    //assuming the list is in the proper order
    func separate_list(_ attendee_list: [Attendee]) -> [[Attendee]] {
        
        var section_index = -1
        var last_letter : String? = nil
        var attendee_section_list = [[Attendee]]()
        
        for (i, attendee) in attendee_list.enumerated() {
            
            let current_letter: String? = attendee.lastname.substring(to: attendee.lastname.characters.index(attendee.lastname.startIndex, offsetBy: 1)).uppercased()
            
            if last_letter == nil || current_letter == nil || last_letter != current_letter {
                //new section
                attendee_section_list.append([Attendee]())
                section_index += 1
            }
            
            attendee_section_list[section_index].append(attendee)
            last_letter = current_letter
            
        }
        return attendee_section_list
    }
    
    func getSectionListFromTable(_ tableView: UITableView) -> [[Attendee]] {
        if tableView == self.searchDisplayController!.searchResultsTableView {
            return filtered_attendees
        }else{
            return attendees
        }
    }
    
    func getAttendeeForRowAtIndexPath(_ tableView: UITableView, indexPath:IndexPath) -> Attendee {
        if tableView == self.searchDisplayController!.searchResultsTableView {
            return filtered_attendees[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).row]
        }else{
            return attendees[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).row]
        }
    }
    
    ///////////////////////////////////////////////////////////
    // used for UISearchBarDelegate, UISearchDisplayDelegate //
    ///////////////////////////////////////////////////////////
    
    func filterContentForSearchText(_ searchText: String) {
        filtered_attendees = [[Attendee]]()
        for (i, section) in attendees.enumerated(){
            self.filtered_attendees.append(section.filter({( attendee: Attendee) -> Bool in
                let text_search = "\(attendee.lastname) \(attendee.title) \(attendee.company) \(attendee.city) \(attendee.state)"
                let stringMatch = text_search.lowercased().range(of: searchText.lowercased())
                return stringMatch != nil
            }))
        }
    }
    
    func searchDisplayController(_ controller: UISearchDisplayController!, shouldReloadTableForSearch searchString: String?) -> Bool {
        self.filterContentForSearchText(searchString!)
        return true
    }
    
    
    /////////////////////////////////////////////////////////////
    // UITableViewDelegate and UITableViewDataSource Protocols //
    /////////////////////////////////////////////////////////////

    override func numberOfSections(in tableView: UITableView) -> Int {
        return getSectionListFromTable(tableView).count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return getSectionListFromTable(tableView)[section].count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "AttendeeCell", for: indexPath) as UITableViewCell
        
        let activity = getAttendeeForRowAtIndexPath(tableView, indexPath: indexPath)

        cell.textLabel!.text = activity.title
        
        var details_array = [activity.company, activity.city, activity.state]
        details_array = details_array.filter({$0 != ""})
        cell.detailTextLabel!.text = details_array.joined(separator: ", ")

        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        var section_list = getSectionListFromTable(tableView)
        
        if section_list.count > section && !section_list[section].isEmpty {
            let attendee = section_list[section][0]
            return attendee.lastname.substring(to: attendee.lastname.characters.index(attendee.lastname.startIndex, offsetBy: 1)).uppercased()
        }else{
            return nil
        }
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]! {
        var section_titles = [String]()
        let section_list = getSectionListFromTable(tableView)
        
        for section in section_list {
            
            if !section.isEmpty {
                let attendee = section[0]
                section_titles.append(section[0].lastname.substring(to: attendee.lastname.characters.index(attendee.lastname.startIndex, offsetBy: 1)).uppercased())
            }
        }
        
        return section_titles
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)  {
        let segueIdentifier = "AttendeeDetails"
        self.performSegue(withIdentifier: segueIdentifier, sender: tableView)
    }
    

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AttendeeDetails" {
            let destinationViewController = segue.destination as! AttendeeDetailsTableViewController
            let tableSender = sender as! UITableView
            let attendee = getAttendeeForRowAtIndexPath(tableSender, indexPath: tableSender.indexPathForSelectedRow!)
            destinationViewController.attendee = attendee
        }
    }
}
