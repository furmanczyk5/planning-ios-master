//
//  LoginViewController.swift
//  planning-ios
//
//  Created by Matthew O'Connor on 2/10/15.
//  Copyright (c) 2015 American Planning Association. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate  {
    
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var errormessage: UILabel!
    
    class func show(_ sender:UIViewController) {
        let vc = sender.storyboard?.instantiateViewController(withIdentifier: "login") as! LoginViewController
        sender.present(vc, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        username.delegate=self
        password.delegate=self
        
        username.tintColor = UIColor(red: 0.0, green: 0.59, blue: 0.33, alpha: 1.0)
        password.tintColor = UIColor(red: 0.0, green: 0.59, blue: 0.33, alpha: 1.0)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(_ touches: (Set<UITouch>!), with event: (UIEvent!)) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField!) -> Bool {
        textField.resignFirstResponder()
        if textField == username {
            password.becomeFirstResponder()
        }
        else if textField == password {
            submitLogin(self)
        }
        return false;
    }
    
    @IBAction func submitLogin(_ sender: AnyObject) {
        
        if let login_username = username.text {
            if let login_password = password.text {
                
                let customLoader = startCustomLoading(self.view, title: "Logging In")

                User.login(login_username, password: login_password, callback: {(success: Bool) in
                    
                    customLoader.removeFromSuperview()
                    
                    if success {
                        self.errormessage.isHidden = true
                        self.errormessage.text = ""
                        self.dismiss(animated: true, completion: {})
                    }else{
                        
                        if !Reachability.isConnectedToNetwork() {
                            self.custom_alert("No Network Connection", message: "Please try again later", actions: [])
                        }
                        
                        self.errormessage.isHidden = false
                        self.errormessage.text = "Login Failed"
                    }
                })
            }
        }
    }
    
    @IBAction func loginCancel(_ sender: UIButton) {
        self.dismiss(animated: true, completion: {})
    }
}
