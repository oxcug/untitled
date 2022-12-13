//
//  PartialModalHostingController.swift
//  untitled
//
//  Created by Mike Choi on 11/8/22.
//

import PanModal
import SwiftUI

final class PartialModalHostingController<Content>: UIHostingController<Content> where Content : View {
}

extension PartialModalHostingController: PanModalPresentable {
    var panScrollable: UIScrollView? {
        return nil
    }

    var topOffset: CGFloat {
        return 0.0
    }
    
    var longFormHeight: PanModalHeight {
        .contentHeight(200)
    }

    var springDamping: CGFloat {
        1.0
    }

    var transitionDuration: Double {
        0.4
    }

    var transitionAnimationOptions: UIView.AnimationOptions {
        return [.allowUserInteraction, .beginFromCurrentState]
    }

    var shouldRoundTopCorners: Bool {
        true
    }

    var showDragIndicator: Bool {
        true
    }
}
