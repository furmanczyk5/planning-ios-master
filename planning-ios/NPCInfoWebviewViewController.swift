//
//  ConferenceViewController.swift
//  planning-ios
//
//  Created by Matthew O'Connor on 2/2/15.
//  Copyright (c) 2015 American Planning Association. All rights reserved.
//

import UIKit

class NPCInfoWebviewViewController: UIViewController, UIWebViewDelegate {
    
    var url : String?
    var customLoader : CustomLoadingView? = nil
    var timer : Timer?
    var initialLoadComplete : Bool = false
    
    var file : String? // use this instead of url for cashed files
    
    @IBOutlet weak var webView: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.scalesPageToFit = true
        webView.frame=self.view.bounds
        
        if let f = file, let managedFile = appCore.files.managedFiles.filter({$0.file == f }).first {
            
            customLoader = startCustomLoading(self.view, title: "", message: "")
            
            let docUrl = appCore.files.getDocUrl(directory:managedFile.directory, file:managedFile.file)!.path
            
            if Reachability.isConnectedToNetwork() { //
                appCore.files.fileRequiresUpdate(managedFile: managedFile, callback: {
                    (_ requiresUpdate:Bool) -> Void in
                    
                    if requiresUpdate {
                        self.customLoader?.title = "Loading"
                        self.customLoader?.message = "Getting latest content"
                        appCore.files.importFile(managedFile: managedFile, callback: {
                            (_ success:Bool) -> Void in
                            if success {
                                let docUrl = appCore.files.getDocUrl(directory:managedFile.directory, file:managedFile.file)!.path
                                self.loadRequest(docUrl)
                            }else{
                                //do an alert
                                self.loadRequest(managedFile.source)
                            }
                        })
                    }else{
                        self.loadRequest(docUrl)
                    }
                })
            }else if appCore.files.fileManager.fileExists(atPath:docUrl) {
                self.loadRequest(docUrl)
            }else{
                custom_alert("No Network Connection", message: "Please try again later.", actions: [(title:"OK", handler: {
                    () -> Void in
                    self.navigationController?.popViewController(animated: true)
                })])
            }
            
        }else{
            let auth_url = User.getAutoLoginUrl(url: "\(url!)")
            self.loadRequest(auth_url)
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        timer?.invalidate()
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /////////////////////////////
    // UIWebViewDelegate stuff //
    /////////////////////////////
    
    func noConnection() {
        if !self.initialLoadComplete {
            custom_alert("Request Timed Out", message: "Please try again", actions: [(title:"OK", handler: {
                () -> Void in
                self.navigationController!.popViewController(animated: true)
            })])
        }
    }
    
    func loadRequest(_ the_url:String?) {
        let requestUrl = URL(string: the_url!)
        let request = URLRequest(url: requestUrl!)
        webView.loadRequest(request)
    }

    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if navigationType == UIWebViewNavigationType.linkClicked {
            let requestUrl = URL(string: User.getAutoLoginUrl(url: "\(request.url!)"))
            UIApplication.shared.openURL(requestUrl!)
            return false
        }else if navigationType == UIWebViewNavigationType.formSubmitted {
            UIApplication.shared.openURL(request.url!)
            return false
        }
        return true
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        if !self.initialLoadComplete {
            if customLoader != nil {
                customLoader?.title = ""
                customLoader?.message = ""
            }else{
                customLoader = startCustomLoading(self.view, title: "", message: "")
            }
            timer = Timer.scheduledTimer(timeInterval: 20.0, target: self, selector: #selector(NPCInfoWebviewViewController.noConnection), userInfo: nil, repeats: false)
        }
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        self.initialLoadComplete = true
        timer?.invalidate()
        customLoader?.removeFromSuperview()
        customLoader = nil
    }
    
    
}
