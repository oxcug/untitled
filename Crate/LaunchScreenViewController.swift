//
//  LaunchScreenViewController.swift
//  untitled
//
//  Created by Mike Choi on 12/10/22.
//

import UIKit

final class LaunchScreenViewController: UIViewController {
    @IBOutlet var underlineWidthConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        underlineWidthConstraint?.isActive = false
//        underlineWidthConstraint = 150
        underlineWidthConstraint?.isActive = true
        
        UIView.animate(withDuration: 0.1, delay: 0) {
            self.view.layoutIfNeeded()
        }
    }
}
