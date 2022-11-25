//
//  MoreTextModalView.swift
//  untitled
//
//  Created by Mike Choi on 11/25/22.
//

import SwiftUI

struct MoreTextModalView: View {
    let title: String
    let text: String
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Text(text)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .padding()
            .frame(maxHeight: .infinity, alignment: .top)
    }
}


struct MoreTextModalView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MoreTextModalView(title: "Title", text: "some really long description here. some really long description here. some really long description here. some really long description here.")
        }
    }
}
