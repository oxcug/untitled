//
//  FolderSelectionView.swift
//  untitled
//
//  Created by Mike Choi on 10/16/22.
//

import SwiftUI

struct FolderSelectionView: View {
    @State var showFolderCreationModal = false
    @Binding var selectedFolder: Folder?
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Core Data
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \PictureFolder.name, ascending: true)], animation: .default)
    var folders: FetchedResults<PictureFolder>
    
    // MARK: -
    
    let selectionFeedback = UISelectionFeedbackGenerator()
    
    var body: some View {
        List {
            ForEach(folders, id: \.self) { coreDataFolder in
                let folder = Folder(coreDataObject: coreDataFolder)
                
                Button {
                    selectionFeedback.selectionChanged()
                    
                    DispatchQueue.main.async {
                        selectedFolder = Folder(coreDataObject: coreDataFolder)
                        dismiss()
                    }
                } label: {
                    HStack(spacing: 10) {
                        Text(folder.emoji ?? "")
                            .font(.system(size: 22, weight: .semibold, design: .default))
                            .frame(width: 40)
                        
                        Text(folder.name)
                            .font(.system(size: 15, weight: .semibold, design: .default))
                        
                        Spacer()
                        
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.bodyText)
                            .opacity(((selectedFolder?.id ?? UUID()) == folder.id) ? 1 : 0)
                            .font(.system(size: 17, weight: .semibold, design: .default))
                    }
                    .padding(.vertical, 10)
                }
            }
            .listRowSeparatorTint(Color.white.opacity(0.1))
            .listRowSeparator(.hidden, edges: .top)
            
            Button {
                selectionFeedback.selectionChanged()
                showFolderCreationModal = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(.bodyText)
                        .font(.system(size: 24, weight: .semibold, design: .default))
                        .frame(width: 40)
                    
                    Text("Create a folder")
                        .modifier(SemiBoldBodyTextModifier())
                }
                .padding(.vertical, 10)
            }
            .listRowSeparatorTint(Color.white.opacity(0.1))
            .listRowSeparator(.hidden, edges: .top)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Select folder")
                    .modifier(SemiBoldBodyTextModifier())
            }
            
            ToolbarCancelButton()
            
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.system(size: 15, weight: .semibold, design: .default))
                        .foregroundColor(.gray)
                }
            }
        }
        .sheet(isPresented: $showFolderCreationModal) {
            NavigationStack {
                FolderCreationView()
            }
        }
    }
}

struct FolderSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            FolderSelectionView(selectedFolder: .constant(nil))
                .environment(\.managedObjectContext, DataController.preview.container.viewContext)
                .preferredColorScheme(.light)
        }
        
        NavigationStack {
            FolderSelectionView(selectedFolder: .constant(nil))
                .environment(\.managedObjectContext, DataController.preview.container.viewContext)
                .preferredColorScheme(.dark)
        }
    }
}
