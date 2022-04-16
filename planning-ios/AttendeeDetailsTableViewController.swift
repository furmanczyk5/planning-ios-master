//
//  AttendeeDetailsTableViewController.swift
//  planning-ios
//
//  Created by Matthew O'Connor on 4/2/15.
//  Copyright (c) 2015 American Planning Association. All rights reserved.
//

import UIKit
import MessageUI

class AttendeeDetailsTableViewController: UITableViewController, MFMailComposeViewControllerDelegate {

    var attendee : Attendee?
    
    @IBOutlet weak var fullname_label: UITableViewCell!
    @IBOutlet weak var company_label: UITableViewCell!
    @IBOutlet weak var citystate_label: UITableViewCell!
    @IBOutlet weak var phone_label: UITableViewCell!
    @IBOutlet weak var email_label: UITableViewCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let a = attendee {
            setDetails()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return section == 0 ? 3 : 2
    }
    
    func setDetails() {
        fullname_label.textLabel!.text = "\(attendee!.title) "
        company_label.textLabel!.text = "\(attendee!.company) "
        citystate_label.textLabel!.text = "\(attendee!.city), \(attendee!.state) "
        phone_label.textLabel!.text = "\(attendee!.phone) "
        email_label.textLabel!.text = "\(attendee!.email) "
        
    }

    @IBAction func sendEmail(_ sender: Any) {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients([email_label.textLabel!.text ?? ""])
            mail.setSubject("Hello")
            mail.setMessageBody("<p>Hello, we were both at conference</p>", isHTML: true)
            present(mail, animated: true, completion: nil)
        } else {
            // show failure alert
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        if result != .failed {
            controller.dismiss(animated: true, completion: nil)
        }
        
        switch result {
        case .saved:
            let alert = UIAlertController(title: "Email saved successfully", message: "Go to the mail app later to edit and send it.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        case .sent:
            let alert = UIAlertController(title: "Email sent successfully", message: nil, preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        case .failed:
            let alert = UIAlertController(title: "Failed to send email", message: nil, preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            print("Mail sent failure: \(error?.localizedDescription)")
        default:
            break
        }
        
    }
}
