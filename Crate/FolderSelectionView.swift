//
//  FolderSelectionView.swift
//  Crate
//
//  Created by Mike Choi on 10/16/22.
//

import SwiftUI

struct FolderSelectionView: View {
    @Binding var folders: Set<Folder>
    let selectionFeedback = UISelectionFeedbackGenerator()
    
    @State var showFolderCreationModal = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            ForEach(FolderStorage.shared.folders, id: \.self) { folder in
                Button {
                    selectionFeedback.selectionChanged()
                    
                    DispatchQueue.main.async {
                        if folders.contains(folder) {
                            folders.remove(folder)
                        } else {
                            folders.insert(folder)
                        }
                    }
                } label: {
                    HStack(spacing: 10) {
                        Text(folder.emoji ?? "")
                            .foregroundColor(.white)
                            .font(.system(size: 22, weight: .semibold, design: .default))
                            .frame(width: 40)
                        
                        Text(folder.name)
                            .foregroundColor(.white)
                            .font(.system(size: 15, weight: .semibold, design: .default))
                        
                        Spacer()
                        
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                            .opacity(folders.contains(folder) ? 1 : 0)
                            .font(.system(size: 17, weight: .semibold, design: .default))
                    }
                    .padding(.vertical, 10)
                }
            }
            .listRowBackground(Color.black)
            .listRowSeparatorTint(Color.white.opacity(0.1))
            .listRowSeparator(.hidden, edges: .top)
               
            Button {
                selectionFeedback.selectionChanged()
                showFolderCreationModal = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(.white)
                        .font(.system(size: 24, weight: .semibold, design: .default))
                        .frame(width: 40)
                    
                    Text("Create a folder")
                        .foregroundColor(.white)
                        .font(.system(size: 15, weight: .semibold, design: .default))
                }
                .padding(.vertical, 10)
            }
            .listRowBackground(Color.black)
            .listRowSeparatorTint(Color.white.opacity(0.1))
            .listRowSeparator(.hidden, edges: .top)
        }
        .listStyle(.plain)
        .background(Color.black)
        .scrollContentBackground(.hidden)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Select folders")
                    .font(.system(size: 15, weight: .semibold, design: .default))
                    .foregroundColor(.white)
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
            FolderSelectionView(folders: .constant([
                .init(id: UUID().uuidString, name: "Favorites", emoji: "⭐", entries: []),
                .init(id: UUID().uuidString, name: "Fall", emoji: "🍁", entries: [])
            ]))
        }
    }
}
