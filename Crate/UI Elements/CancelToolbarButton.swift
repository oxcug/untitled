//
//  CancelToolbarButton.swift
//  untitled
//
//  Created by Mike Choi on 10/17/22.
//

import SwiftUI

struct ToolbarCancelButton: ToolbarContent {
    @Environment(\.dismiss) private var dismiss
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(role: .cancel) {
                dismiss()
            } label: {
                Text("Cancel")
                    .font(.system(size: 15, weight: .semibold, design: .default))
                    .foregroundColor(.gray)
            }
        }
    }
}
