//
//  CustomLoadingView.swift
//  planning-ios
//
//  Created by Matthew O'Connor on 2/26/15.
//  Copyright (c) 2015 American Planning Association. All rights reserved.
//

import UIKit

@IBDesignable
class CustomLoadingView: UIView {

    @IBOutlet weak var title_label: UILabel!
    @IBOutlet weak var message_label: UILabel!
    @IBOutlet weak var animationContainer_view: UIView!
    
    fileprivate var proxyView: CustomLoadingView?
    
    @IBInspectable open var title: String = "" {
        didSet {
            self.proxyView!.title_label.text = title
        }
    }
    
    @IBInspectable open var message: String = "" {
        didSet {
            self.proxyView!.message_label.text = message
        }
    }
    
    @IBInspectable var cornerRadius: CGFloat = 4 {
        didSet {
            self.proxyView!.animationContainer_view.layer.cornerRadius = cornerRadius
            self.proxyView!.animationContainer_view.layer.masksToBounds = true
        }
    }
    
    
    
    
    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        
    }
    
    override init(frame: CGRect ) {
        super.init(frame: frame)
        let view = self.loadNib()
        view.frame = self.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.proxyView = view
        self.addSubview(self.proxyView!)
        
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func awakeAfter(using aDecoder: NSCoder) -> Any? {
        if self.subviews.count == 0 {
            let view = self.loadNib()
            view.translatesAutoresizingMaskIntoConstraints = false
            let contraints = self.constraints
            self.removeConstraints(contraints)
            view.addConstraints(contraints)
            view.proxyView = view
            return view
        }
        return self
    }
    
    fileprivate func loadNib() -> CustomLoadingView {
        let bundle = Bundle(for: type(of: self))
        let view = bundle.loadNibNamed("CustomLoadingView", owner: nil, options: nil)?[0] as! CustomLoadingView
        return view
    }

}

func startCustomLoading(_ parent: UIView, title: String = "Loading", message: String = "") -> CustomLoadingView {
    
    let loadingView = CustomLoadingView(frame: CGRect(x: 0, y: 0, width: 300, height: 400))
    loadingView.isOpaque = false
    
    parent.addSubview(loadingView)
    loadingView.title = title
    loadingView.message = message
    loadingView.cornerRadius = 4
    
    loadingView.translatesAutoresizingMaskIntoConstraints = false
    
    let views = Dictionary(dictionaryLiteral: ("loadingView",loadingView))
    
    let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[loadingView]|", options: [], metrics: nil, views: views)
    parent.addConstraints(horizontalConstraints)
    
    let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[loadingView]|", options: [], metrics: nil, views: views)
    parent.addConstraints(verticalConstraints)
    
    return loadingView
}

