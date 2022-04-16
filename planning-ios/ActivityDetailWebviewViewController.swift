//
//  ActivityDetailWebviewViewController.swift
//  planning-ios
//
//  Created by Randall West on 3/20/15.
//  Copyright (c) 2015 American Planning Association. All rights reserved.
//

import UIKit

class ActivityDetailWebviewViewController: ActivityDetailViewController, UIWebViewDelegate {
    
    @IBOutlet weak var details_webview: UIWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        set_details_webview()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func set_details_webview() {
        
        let activity_id = activity!.id
        
        let url = "\(appCore.site_domain)/mobile/events/nationalconferenceactivity/\(activity_id)/"
        let requestUrl = URL(string: User.getAutoLoginUrl(url: "\(url)"))
        let request = URLRequest(url: requestUrl!)
    
        details_webview.scalesPageToFit = true
        details_webview.frame=self.view.bounds
        details_webview.dataDetectorTypes = []
        details_webview.loadRequest(request)
    }
    
    /////////////////////////////
    // UIWebViewDelegate stuff //
    /////////////////////////////
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

}
