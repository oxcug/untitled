//
//  DemoPanelDelegate.swift
//  Crate
//
//  Created by Mike Choi on 10/24/22.
//

import SwiftUI
import FloatingPanel

final class DemoPanelLayout: FloatingPanelLayout {
    var initialState: FloatingPanelState {
        .full
    }
    
    var position: FloatingPanelPosition {
        .bottom
    }
    
    var anchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] {
        return [
            .full: FloatingPanelLayoutAnchor(absoluteInset: 0.0, edge: .top, referenceGuide: .superview),
            .half: FloatingPanelLayoutAnchor(fractionalInset: 0.5, edge: .bottom, referenceGuide: .superview),
            .hidden: FloatingPanelLayoutAnchor(absoluteInset: 0, edge: .bottom, referenceGuide: .superview)
        ]
    }
}

final class DemoFloatingPanelDelegate: FloatingPanelControllerDelegate, ObservableObject {
    func floatingPanel(_ fpc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout {
        fpc.surfaceView.grabberHandle.isHidden = true
        return DemoPanelLayout()
    }
    
    func floatingPanel(_ fpc: FloatingPanelController, shouldRemoveAt location: CGPoint, with velocity: CGVector) -> Bool {
        return false
    }
}
