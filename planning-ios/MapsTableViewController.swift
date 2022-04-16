//
//  MapsTableViewController.swift
//  planning-ios
//
//  Created by Matthew O'Connor on 11/4/16.
//  Copyright © 2016 American Planning Association. All rights reserved.
//

import UIKit

class MapsTableViewController: UITableViewController {
    
    let urlForIndex = [
        (type:"file",   value:"javits-level-1.pdf"),
        (type:"file",   value:"marriot-activities.pdf"),
        (type:"file",   value:"javits-1C.pdf"),
        (type:"file",   value:"javits-1A.pdf"),
        (type:"file",   value:"javits-1E.pdf"),
        (type:"file",   value:"javits-1D.pdf")
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)  {
        let segueIdentifier = "ViewMap"
        self.performSegue(withIdentifier: segueIdentifier, sender: tableView)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationViewController = segue.destination as! NPCInfoWebviewViewController
        let sender_uitableview = sender as! UITableView
        let indexPath = sender_uitableview.indexPathForSelectedRow
        let indexPathObject = urlForIndex[(indexPath! as NSIndexPath).row]
        
        if indexPathObject.type == "file" {
            destinationViewController.file = indexPathObject.value
        }else{
            destinationViewController.url = indexPathObject.value + "?auth_user_id=\(User.user_id ?? "")&auth_token=\(User.token ?? "")&auth_login=true&mobile_app=true"
        }
        
        destinationViewController.title = sender_uitableview.cellForRow(at: indexPath!)!.textLabel!.text
    }

}
