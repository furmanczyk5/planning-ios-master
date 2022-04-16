//
//  HomeViewController.swift
//  planning-ios
//
//  Created by Matthew O'Connor on 3/26/15.
//  Copyright (c) 2015 American Planning Association. All rights reserved.
//

import UIKit
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var program_option : ProgramOption? = ProgramOption(title: "Now", filter: .upnext)
    var activities = [[Activity]]()
    var refreshControl : UIRefreshControl?
    var view_already_loaded = false // so we don't make same server calls twice, the first time
    
    // list of tuples for static cells
    var staticCells : [(cellIdentifier:String,context:AnyObject?)] = []
    var customLoader : CustomLoadingView?
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 205.0
        
        //sets selected image tint color
        self.tabBarController?.tabBar.selectedImageTintColor = UIColor(red: 0.0, green: 0.33, blue: 0.58, alpha: 1.0)
        
        staticCells = [(cellIdentifier:"InfoCell", context:nil)]
        
        //checking if we need to update program bcause of an update
        let checkpointInteger = UserDefaults.standard.integer(forKey: "CheckpointInteger")
        let lastCheckpoint = 20161031 //for Nov 30 2015
        
        if Activity.all().isEmpty {
            reloadActivities()
        }else if checkpointInteger != lastCheckpoint {
            reloadActivities()
            UserDefaults.standard.set(lastCheckpoint, forKey: "CheckpointInteger")
        }else{
            setActivities()
            self.tableView.reloadData()
        }
        reloadMessage()
        
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(HomeViewController.refresh), for: UIControlEvents.valueChanged)
        self.tableView.addSubview(refreshControl)
        self.refreshControl = refreshControl
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if view_already_loaded {
            setActivities()
            self.tableView.reloadData()
            reloadMessage()
        }
        view_already_loaded = true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if segue.identifier == "activityDetailWebview" || segue.identifier == "activityDetailNative" {
            
            let activityDetailViewController = segue.destination as! ActivityDetailViewController
            let sender_uitableview = sender as! UITableView
            let indexPath = (sender as AnyObject).indexPathForSelectedRow!
            activityDetailViewController.activity = getActivityForRowAtIndexPath(sender_uitableview, indexPath: indexPath!)
            
        }
    }
    
    // called when the user refreshes the page
    func refresh() {
        reloadActivities()
        reloadMessage()
    }
    
    @IBAction func headerBarRefresh(_ sender: AnyObject) {
        refresh()
    }
    
    func reloadMessage() {
        
        let MESSAGE_ID = "9000174" //put id for content message here
        
        Content.getContent(MESSAGE_ID, callback: { (success, content) -> Void in
            
            if success {
                
                if let oldcell = self.staticCells.first, let oldcontent = oldcell.context as? Content , let newcontent = content {
                    
                    self.staticCells = [(cellIdentifier:"InfoCell", context:content)]
                    
                    if oldcontent.text != newcontent.text {
                        self.tableView.reloadData()
                        self.tableView.beginUpdates()
                        self.tableView.endUpdates()
                    }
                    
                }else{
                    
                    self.staticCells = [(cellIdentifier:"InfoCell", context:content)]
                    
                    self.tableView.reloadData()
                    self.tableView.beginUpdates()
                    self.tableView.endUpdates()
                }
                
            }
            
        })
    }
    
    // imports data from the server into core data, then sets activities on the table
    func reloadActivities() {
        //assuming there is always a data_source
        let is_schedule : Bool = program_option!.data_source == .myschedule
        
        let loader_message = is_schedule ? "Getting your schedule..." : "Getting Conference Program..."
        self.customLoader = startCustomLoading(self.navigationController!.view, message:loader_message)
        
        let reloadAllHandler = {(success:Bool) -> Void in
            if success {
                self.setActivities()
                self.tableView.reloadData()
                self.refreshControl?.endRefreshing()
            }else{
                self.refreshControl?.endRefreshing()
                
                if !is_schedule || User.isAuthenticated() {
                    self.custom_alert("Update Failed", message: "Could not connect to the server. Please Try again.")
                }else{
                    self.custom_alert("You Are Not Logged In", message: "Go to Login to view and make changes to your schedule", actions: [(title:"Go to Login", handler: {
                        () -> Void in
                        LoginViewController.show(self)
                    })])
                }
            }
            self.customLoader?.removeFromSuperview()
            self.customLoader = nil
        }
        
        if is_schedule {
            Activity.pullMyschedule(appCore.managedContext, callback: reloadAllHandler)
        }else{
            Activity.pullAll(appCore.managedContext, callback: reloadAllHandler)
        }
    }
    
    // sets the activities from core data
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
        
        switch self.program_option!.filter {
        case .upnext:
            activities_list = ProgramOption.upNextFilter(activities_list)
        default:
            activities_list = activities_list.filter(self.program_option!.filter_closure)
        }
        
        let max_results = self.program_option!.max_results
        if max_results != nil && max_results > 0 && activities_list.count > max_results {
            activities_list = Array(activities_list[0...max_results!])
        }
        
        self.activities = self.separate_list(activities_list)
        
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
    
    //////////////////////////////////////////////////////////////////
    // OVERRIDE NEXT TWO METHODS IF YOU ARE IMPLEMENTING SEARCH BAR //
    //////////////////////////////////////////////////////////////////
    func getSectionListFromTable(_ tableView: UITableView) -> [[Activity]] {
        return activities
    }
    
    
    
    func getActivityForRowAtIndexPath(_ tableView: UITableView, indexPath:IndexPath) -> Activity {
        return activities[(indexPath as NSIndexPath).section - staticCells.count][(indexPath as NSIndexPath).row]
    }
    
    
    /////////////////////////////////////////////////////////////
    // UITableViewDelegate and UITableViewDataSource Protocols //
    /////////////////////////////////////////////////////////////
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return activities.count + staticCells.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let section_list = getSectionListFromTable(tableView)
        
        if section < staticCells.count{
            return 1
        }else if section_list.count > section - staticCells.count {
            return section_list[section - staticCells.count].count
        }else{
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if (indexPath as NSIndexPath).section < staticCells.count {
            // deque static cell
            let prototypeCellId = staticCells[(indexPath as NSIndexPath).section].cellIdentifier
            let cell = self.tableView.dequeueReusableCell(withIdentifier: prototypeCellId, for: indexPath) as! StaticInfoTableViewCell
            cell.setContent(staticCells[(indexPath as NSIndexPath).section].context)
            return cell
            
        }else{
            let cell = self.tableView.dequeueReusableCell(withIdentifier: "activityCell", for: indexPath) as! ActivityTableViewCell
            var activity = getActivityForRowAtIndexPath(tableView, indexPath: indexPath)
            cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
            cell.setContent(activity)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let section_list = getSectionListFromTable(tableView)
        
        let data_section = section - staticCells.count
        
        if data_section >= 0 && section_list.count > data_section && !section_list[data_section].isEmpty {
            let header_label    : UILabel = UILabel()
            let header_wrapper  : UIView  = UIView()
            
            header_wrapper.backgroundColor = UIColor.darkGray
            header_label.textColor = UIColor.white
            header_label.font = UIFont.systemFont(ofSize: 16)
            header_label.text = section_list[data_section][0].date_string
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
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        let section_list = getSectionListFromTable(tableView)
        
        let data_section = section - staticCells.count
        
        if data_section >= 0 && section_list.count > data_section && !section_list[data_section].isEmpty {
            return 24.0
        }else{
            return 0.0
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)  {
        if (indexPath as NSIndexPath).section >= staticCells.count {
            let segueIdentifier = Reachability.isConnectedToNetwork() ? "activityDetailWebview" : "activityDetailNative"
            self.performSegue(withIdentifier: segueIdentifier, sender: tableView)
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

}
