//
//  FloatingPanelDelegate.swift
//  Crate
//
//  Created by Mike Choi on 10/18/22.
//

import SwiftUI
import FloatingPanel

final class SavedMapPanelLayout: FloatingPanelLayout {
    var initialState: FloatingPanelState {
        .hidden
    }
    
    var position: FloatingPanelPosition {
        .left
    }
    
    var anchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] {
        return [
            .full: FloatingPanelLayoutAnchor(absoluteInset: 0.0, edge: .top, referenceGuide: .superview),
            .hidden: FloatingPanelLayoutAnchor(absoluteInset: 0, edge: .bottom, referenceGuide: .superview)
        ]
    }
}

final class DetailFloatingPanelDelegate: FloatingPanelControllerDelegate, ObservableObject {    
    func floatingPanel(_ fpc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout {
        fpc.surfaceView.grabberHandle.isHidden = true
        return SavedMapPanelLayout()
    }
    
    func floatingPanel(_ fpc: FloatingPanelController, shouldRemoveAt location: CGPoint, with velocity: CGVector) -> Bool {
        return false
    }
}

