//
//  ActivityTableViewController.swift
//  planning-ios
//
//  Created by Matthew O'Connor on 2/12/15.
//  Copyright (c) 2015 American Planning Association. All rights reserved.
//

import UIKit

class ActivityTableViewController: UITableViewController, UISearchBarDelegate, UISearchResultsUpdating {
    
    var filteredActivities = [[Activity]]()
    var activities = [[Activity]]()
    
    var program_option : ProgramOption?
    
    let searchController = UISearchController(searchResultsController: nil)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        extendedLayoutIncludesOpaqueBars = true
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(ActivityTableViewController.reloadAll), for: UIControlEvents.valueChanged)
        self.refreshControl = refreshControl
        
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search or Filter By Day"
        searchController.searchBar.scopeButtonTitles = ["All", "Sat", "Sun", "Mon", "Tue"]
        searchController.searchBar.delegate = self
        searchController.searchBar.tintColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        
        definesPresentationContext = true
        
        tableView.tableHeaderView = searchController.searchBar
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 200.0
        
    
        if program_option!.data_source != .myschedule {
            
            if Activity.all().isEmpty {
                reloadAll()
            }else{
                setActivities()
            }
            
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if program_option!.data_source == .myschedule {
            reloadAll()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func headerBarRefresh(_ sender: AnyObject) {
        reloadAll()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        // Return the number of sections.
        return activities.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        var section_list : [[Activity]]
        if searchController.isActive {
            section_list = filteredActivities
        }else{
            section_list = activities
        }
        
        if section_list.count > section {
            return section_list[section].count
        }else{
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "activityCell", for: indexPath) as! ActivityTableViewCell
        var activity: Activity
        
        if searchController.isActive {
            activity = filteredActivities[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).row]
        }else{
            activity = activities[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).row]
        }
        
        cell.setContent(activity)
        cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
    
        return cell
    }
    
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        // Filter the array using the filter method
        filteredActivities = [[Activity]]()
        
        var filter_date_string:String?
        switch scope {
        case "All":
            filter_date_string = nil
        case "Sat":
            filter_date_string = "2017-05-06"
        case "Sun":
            filter_date_string = "2017-05-07"
        case "Mon":
            filter_date_string = "2017-05-08"
        case "Tue":
            filter_date_string = "2017-05-09"
        default:
            filter_date_string = nil
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier:appCore.timeZoneName)
        
        for section in activities {
            self.filteredActivities.append(section.filter({( activity: Activity) -> Bool in
                
                var matches_scope = true
                
                if let fds = filter_date_string {
                    if let begin_time = activity.begin_time {
                        matches_scope = dateFormatter.string(from: begin_time as Date) == fds
                    }else{
                        matches_scope = false
                    }
                }else{
                    matches_scope = true
                }
                
                if matches_scope {
                    if searchText == "" {
                        return true
                    }else{
                        let speakers_array = activity.speakers.allObjects.map({($0 as AnyObject).title as String})
                        let text_search = "\(activity.title) \(activity.code) ,\(speakers_array.description), ,\(activity.tags),"
                        let stringMatch = text_search.lowercased().range(of: searchText.lowercased())
                        return stringMatch != nil
                    }
                }else{
                    return false
                }
                
            }))
        }
        
        tableView.reloadData()
    }
    
    func updateSearchResults(for: UISearchController) {
        let searchBar = searchController.searchBar
        let scope = searchBar.scopeButtonTitles![searchBar.selectedScopeButtonIndex]
        filterContentForSearchText(searchController.searchBar.text!, scope: scope)
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        filterContentForSearchText(searchBar.text!, scope: searchBar.scopeButtonTitles![selectedScope])
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        var section_list : [[Activity]]
        if searchController.isActive {
            section_list = filteredActivities
        }else{
            section_list = activities
        }
        
        if section_list.count > section && !section_list[section].isEmpty {
            let header_label    : UILabel = UILabel()
            let header_wrapper  : UIView  = UIView()
            
            header_wrapper.backgroundColor = UIColor.darkGray
            header_label.textColor = UIColor.white
            header_label.font = UIFont.systemFont(ofSize: 16)
            header_label.text = section_list[section][0].date_string
            header_label.translatesAutoresizingMaskIntoConstraints = false
            header_wrapper.addSubview(header_label)
            
            let views = Dictionary(dictionaryLiteral: ("header_label",header_label), ("view",header_wrapper))
            
            let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-8-[header_label]|", options: [], metrics: nil, views: views)
            let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[header_label]|", options: [], metrics: nil, views: views)
            header_wrapper.addConstraints(horizontalConstraints)
            header_wrapper.addConstraints(verticalConstraints)
        
            return header_wrapper
        }else{
            return nil
        }
        
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        var section_list : [[Activity]]
        if searchController.isActive {
            section_list = filteredActivities
        }else{
            section_list = activities
        }
        
        if section_list.count > section && !section_list[section].isEmpty {
            return 24.0
        }else{
            return 0.0
        }
    }
    
// REMOVE - UISearchDisplayController is deprecated
//    func searchDisplayController(_ controller: UISearchDisplayController!, shouldReloadTableForSearch searchString: String?) -> Bool {
//        let scope = controller.searchBar.scopeButtonTitles![controller.searchBar.selectedScopeButtonIndex]
//        self.filterContentForSearchText(searchString!, scope: scope)
//        return true
//    }
    
    func reloadAll() {
        /*  Calling this will make a call to the solr server and update the global var appActivities.
            Then it will call reload data on the table
            This can be used both to initialize the table, and to reload data
        */
        
        //assuming there is always a data_source
        let is_schedule : Bool = program_option!.data_source == .myschedule
        
        let loader_message = is_schedule ? "Getting your schedule..." : "Getting Conference Program..."
        let customLoader = startCustomLoading(self.navigationController!.view, message:loader_message)
        
        let reloadAllHandler = {(success:Bool) -> Void in
            
            self.setActivities()
            self.refreshControl?.endRefreshing()
            
            if !success{
                
                if is_schedule && !User.isAuthenticated() {
                    self.custom_alert("You Are Not Logged In", message: "Go to Login to view and make changes to your schedule", actions: [(title:"Go to Login", handler: {
                        () -> Void in
                        LoginViewController.show(self)
                    })])
                }else if !is_schedule{
                    self.custom_alert("Update Failed", message: "Could not connect to the server. Please Try again.")
                }
            }
            customLoader.removeFromSuperview()
        }
        
        if is_schedule {
            Activity.pullMyschedule(appCore.managedContext, callback: reloadAllHandler)
        }else{
            Activity.pullAll(appCore.managedContext, callback: reloadAllHandler)
        }
    }
    
    func setActivities() {
        
        var activities_list : [Activity] = []
        
        switch self.program_option!.data_source {
        case .program:
            activities_list = Activity.all()
        case .myschedule:
            activities_list = Activity.myschedule()
        default:
            break
        }
        
        activities_list = activities_list.filter(self.program_option!.filter_closure)
        
        self.activities = self.separate_list(activities_list)
        self.filteredActivities = self.activities
        
        self.tableView.reloadData()
    }
    
    //assuming the list is in the proper order
    func separate_list(_ activity_list: [Activity]) -> [[Activity]] {
        
        var section_index = -1                   // the first activity should always start a new section and change to 0
        var last_date_formatted : String? = nil
        var activity_section_list = [[Activity]]()
        
        for (i, activity) in activity_list.enumerated() {
            
            let this_date_formatted = activity.date_string
            
            if last_date_formatted == nil || this_date_formatted == nil || last_date_formatted != this_date_formatted {
                //new section
                activity_section_list.append([Activity]())
                section_index += 1
            }
            
            activity_section_list[section_index].append(activity)
            last_date_formatted = this_date_formatted
            
        }
        return activity_section_list
    }

    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)  {
        let segueIdentifier = Reachability.isConnectedToNetwork() ? "activityDetailWebview" : "activityDetailNative"
        self.performSegue(withIdentifier: segueIdentifier, sender: tableView)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if segue.identifier == "activityDetailWebview" || segue.identifier == "activityDetailNative" {
            let activityDetailViewController = segue.destination as! ActivityDetailViewController
            let indexPath = self.tableView.indexPathForSelectedRow!
            if searchController.isActive {
                let destinationActivity = self.filteredActivities[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).row]
                activityDetailViewController.activity = destinationActivity
            } else {
                let destinationActivity = activities[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).row]
                activityDetailViewController.activity = destinationActivity
            }
        }
    }
}
