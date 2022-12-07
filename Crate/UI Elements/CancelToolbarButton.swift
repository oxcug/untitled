//
//  CancelToolbarButton.swift
//  untitled
//
//  Created by Mike Choi on 10/17/22.
//

import SwiftUI

struct ToolbarCancelButton: ToolbarContent {
    @Environment(\.dismiss) private var dismiss
    var willDismiss: (() -> ())?
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(role: .cancel) {
                willDismiss?()
                dismiss()
            } label: {
                Text("cancel")
                    .font(.system(size: 17, weight: .semibold, design: .default))
                    .foregroundColor(.secondary)
            }
        }
    }
}
