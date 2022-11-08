//
//  DetailNavigationController.swift
//  Crate
//
//  Created by Mike Choi on 11/6/22.
//

import Combine
import PanModal
import SwiftUI

final class FullScreenHostingController<Content>: UIHostingController<Content> where Content : View {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
}

extension FullScreenHostingController: PanModalPresentable {
    var panScrollable: UIScrollView? {
        return nil
    }

    var topOffset: CGFloat {
        return 0.0
    }

    var springDamping: CGFloat {
        return 1.0
    }

    var transitionDuration: Double {
        return 0.4
    }

    var transitionAnimationOptions: UIView.AnimationOptions {
        return [.allowUserInteraction, .beginFromCurrentState]
    }

    var shouldRoundTopCorners: Bool {
        true
    }

    var showDragIndicator: Bool {
        false
    }
}
