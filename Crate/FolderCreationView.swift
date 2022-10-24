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
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var viewContext
    
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
                createFolder()
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
            
            ToolbarCancelButton()
        }
        .onAppear {
            focusOnTextField = true
        }
    }
    
    private func createFolder() {
        let folder = PictureFolder(context: viewContext)
        folder.id = UUID()
        folder.name = name
        folder.emoji = emoji
        folder.entries = NSOrderedSet(array: [])
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}

struct FolderCreationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            FolderCreationView()
                .environment(\.managedObjectContext, DataController.preview.container.viewContext)
        }
    }
}
