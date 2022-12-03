//
//  RootNavigationController.swift
//  untitledShareExtension
//
//  Created by Mike Choi on 11/28/22.
//

import Foundation
import UIKit

@objc(RootNavigationController)
class RootNavigationController: UINavigationController {
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        self.setViewControllers([ShareViewController()], animated: false)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
