//
//  FolderCreationView.swift
//  Crate
//
//  Created by Mike Choi on 10/16/22.
//

import Combine
import SwiftUI

struct FolderCreationView: View {
    @State var name = ""
    @State var emoji = "🔥"
    @State var keyboardHeight: CGFloat = .zero
    @FocusState var focusOnTextField: Bool
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 30) {
            EmojiTextField(text: $emoji)
                .frame(height: 50)
                .padding()
                .background(Circle().foregroundColor(.white.opacity(0.08)))
                .padding(.top, 10)
            
            TextField("folder name", text: $name)
                .multilineTextAlignment(.center)
                .padding()
                .font(.system(size: 24, weight: .semibold, design: .default))
                .background(RoundedRectangle(cornerRadius: 10).foregroundColor(.white.opacity(0.08)))
                .foregroundColor(.white)
                .focused($focusOnTextField)
             
            Spacer()
            
            Button {
                FolderStorage.shared.createFolder(name: name, emoji: emoji, entries: [])
                dismiss()
            } label: {
                Text("create folder")
                    .font(.system(size: 15, weight: .semibold, design: .default))
                    .foregroundColor(Color(uiColor: .black))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).foregroundColor(Color(uiColor: .white)))
            }
            .background(Rectangle().foregroundColor(.black))
        }
        .padding()
        .background(Color.black)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("New folder")
                    .font(.system(size: 15, weight: .semibold, design: .default))
                    .foregroundColor(.white)
            }
            
            ToolbarItem(placement: .cancellationAction) {
                Button(role: .cancel) {
                    dismiss()
                } label: {
                    Text("Close")
                        .font(.system(size: 15, weight: .semibold, design: .default))
                        .foregroundColor(.gray)
                }
            }
        }
        .onAppear {
            focusOnTextField = true
        }
    }
}

struct FolderCreationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            FolderCreationView()
        }
    }
}
