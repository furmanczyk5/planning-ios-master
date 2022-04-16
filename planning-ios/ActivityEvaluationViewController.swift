//
//  ActivityEvaluationViewController.swift
//  planning-ios
//
//  Created by Matthew O'Connor on 3/25/15.
//  Copyright (c) 2015 American Planning Association. All rights reserved.
//

import UIKit

class ActivityEvaluationViewController: UIViewController, UIWebViewDelegate {
    
    var activity : Activity?
    
    var customLoader : CustomLoadingView? = nil
    var timer : Timer?
    
    var user_id = User.user_id!

    @IBOutlet weak var evaluation_webview: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if Reachability.isConnectedToNetwork() {
            set_evaluation_webview()
        }else{
            custom_alert("No Network Connection", message: "Please try again later", actions: [])
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !User.isAuthenticated() {
            self.navigationController!.popViewController(animated: true)
        }else if User.user_id! != user_id {
            user_id = User.user_id!
            evaluation_webview.reload()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        timer?.invalidate()
    }
    
    func set_evaluation_webview() {
        
        let activity_id = activity!.id
        let is_aicp : Bool = User.hasWebGroup("aicp_cm") || User.hasWebGroup("reinstatement_cm")
        var url = ""
        
        if is_aicp {
            url = "\(appCore.site_domain)/mobile/cm/log/claim/event/\(activity_id)/"
        }else{
            url = "\(appCore.site_domain)/mobile/events/\(activity_id)/evaluation/"
        }

        let requestUrl = URL(string: User.getAutoLoginUrl(url: "\(url)"))
        let request = URLRequest(url: requestUrl!)
        
        evaluation_webview.scalesPageToFit = true
        evaluation_webview.frame=self.view.bounds
        evaluation_webview.loadRequest(request)
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
        }
        return true
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        customLoader = startCustomLoading(self.view, title: "", message: "")
        timer = Timer.scheduledTimer(timeInterval: 20.0, target: self, selector: #selector(ActivityEvaluationViewController.noConnection), userInfo: nil, repeats: false)
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        timer?.invalidate()
        customLoader?.removeFromSuperview()
        customLoader = nil
    }

}
