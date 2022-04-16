//
//  ProgramTableViewController.swift
//  planning-ios
//
//  Created by Matthew O'Connor on 2/24/15.
//  Copyright (c) 2015 American Planning Association. All rights reserved.
//

import UIKit

class ProgramTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 64
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return PROGRAM_TABLE_OPTIONS.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return PROGRAM_TABLE_OPTIONS[section].options.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "program_option", for: indexPath) as! SubtitleTableViewCell
        let program_option = PROGRAM_TABLE_OPTIONS[(indexPath as NSIndexPath).section].options[(indexPath as NSIndexPath).row]

        cell.title = program_option.title
        cell.subtitle = program_option.description ?? ""

        return cell
    }
    
//    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//    
//        var label : UILabel = UILabel()
//        label.text = PROGRAM_TABLE_OPTIONS[section].section
//
//        return label
//    }
//    
//    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        
//        return 32.0
//    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String {
        return PROGRAM_TABLE_OPTIONS[section].section
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "activity_table", sender: tableView)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if segue.identifier == "activity_table" {
            let activityTableViewController = segue.destination as! ActivityTableViewController
            let indexPath = self.tableView.indexPathForSelectedRow!
            let destinationProgramOption = PROGRAM_TABLE_OPTIONS[(indexPath as NSIndexPath).section].options[(indexPath as NSIndexPath).row]
            activityTableViewController.title = destinationProgramOption.title
            activityTableViewController.program_option = destinationProgramOption
            
        }
    }
    
//    override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
//        
//        self.layoutIfNeeded()
//        var size = super.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: horizontalFittingPriority, verticalFittingPriority: verticalFittingPriority)
//        if let textLabel = self.textLabel, let detailTextLabel = self.detailTextLabel {
//            let detailHeight = detailTextLabel.frame.size.height
//            if detailTextLabel.frame.origin.x > textLabel.frame.origin.x { // style = Value1 or Value2
//                let textHeight = textLabel.frame.size.height
//                if (detailHeight > textHeight) {
//                    size.height += detailHeight - textHeight
//                }
//            } else { // style = Subtitle, so always add subtitle height
//                size.height += detailHeight
//            }
//        }
//        return size
//    }
    
    

}
