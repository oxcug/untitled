//
//  SettingsPanelDelegate.swift
//  Crate
//
//  Created by Mike Choi on 10/24/22.
//

import FloatingPanel
import UIKit

final class SettingsPanelLayout: FloatingPanelLayout {
    var initialState: FloatingPanelState {
        .hidden
    }
    
    var position: FloatingPanelPosition {
        .bottom
    }
    
    var anchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] {
        [
            .full: FloatingPanelLayoutAnchor(absoluteInset: 200, edge: .bottom, referenceGuide: .superview),
            .hidden: FloatingPanelLayoutAnchor(absoluteInset: 0, edge: .bottom, referenceGuide: .superview)
        ]
    }
}

final class SettingsPanelDelegate: FloatingPanelControllerDelegate, ObservableObject {
    var fpc: FloatingPanelController?
    
    lazy var backdropHideGestureRecognizer: UITapGestureRecognizer = {
        let gr = UITapGestureRecognizer()
        gr.addTarget(self, action: #selector(lowerModal))
        return gr
    }()
    
    func floatingPanel(_ fpc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout {
        self.fpc = fpc
        fpc.backdropView.addGestureRecognizer(backdropHideGestureRecognizer)
        fpc.isRemovalInteractionEnabled = false
        return SettingsPanelLayout()
    }
    
    func floatingPanel(_ fpc: FloatingPanelController, shouldRemoveAt location: CGPoint, with velocity: CGVector) -> Bool {
        return false
    }
    
    @objc func lowerModal() {
        fpc?.move(to: .hidden, animated: true)
    }
}
