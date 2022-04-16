//
//  MyApaWebViewController.swift
//  planning-ios
//
//  Created by Matthew O'Connor on 3/30/15.
//  Copyright (c) 2015 American Planning Association. All rights reserved.
//

import UIKit

class MyApaWebViewController: UIViewController, UIWebViewDelegate {
    
    var url : String?
    var timer : Timer?
    @IBOutlet weak var myapa_webview: UIWebView!
    
    var customLoader : CustomLoadingView? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !User.isAuthenticated() {
            custom_alert("User Unauthorized", message: "Log in to view and edit your My APA account", actions: [])
        }else if !Reachability.isConnectedToNetwork() {
            custom_alert("No Network Connection", message: "Please try again later.", actions: [])
        }else{
            let requestUrl = URL(string: User.getAutoLoginUrl(url: "\(url!)"))
            let request = URLRequest(url: requestUrl!)
            
            myapa_webview.scalesPageToFit = true
            myapa_webview.frame=self.view.bounds
            myapa_webview.loadRequest(request)
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
        custom_alert("Request Timed Out", message: "Please try again", actions: [(title:"Cancel Request", handler: {
            () -> Void in
            print("request cancelled")
            self.navigationController!.popViewController(animated: true)
        })])
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
        customLoader = startCustomLoading(self.view, title: "", message: "")
        timer = Timer.scheduledTimer(timeInterval: 20.0, target: self, selector: #selector(MyApaWebViewController.noConnection), userInfo: nil, repeats: false)
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        timer?.invalidate()
        customLoader?.removeFromSuperview()
        customLoader = nil
    }

}
