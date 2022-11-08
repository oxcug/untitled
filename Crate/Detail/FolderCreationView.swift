//
//  FolderCreationView.swift
//  Crate
//
//  Created by Mike Choi on 10/16/22.
//

import Combine
import SwiftUI

struct FolderCreationView: View {
    var folder: Folder?
    
    @State var name = ""
    @State var emoji = "🔥"
    @State var actionText: String = ""
    @State var keyboardHeight: CGFloat = .zero
    @FocusState var focusOnTextField: Bool
       
    var didUpdateName: ((String) -> ())?
    
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
                if folder != nil {
                    updateFolder()
                } else {
                    createFolder()
                }
                dismiss()
            } label: {
                Text(actionText.lowercased())
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
                Text(actionText)
                    .font(.system(size: 15, weight: .semibold, design: .default))
                    .foregroundColor(.white)
            }
            
            ToolbarCancelButton()
        }
        .task {
            if let folder = folder {
                name = folder.name
                emoji = folder.emoji ?? ""
            }
            
            actionText = "\(folder == nil ? "New": "Update") folder"
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
    
    private func updateFolder() {
        if let coreDataObject = folder?.coreDataObject {
            coreDataObject.name = name
            coreDataObject.emoji = emoji
            didUpdateName?("\(emoji) \(name)")
            try? viewContext.save()
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
