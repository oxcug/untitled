//
//  FolderDetailView.swift
//  Crate
//
//  Created by Mike Choi on 11/8/22.
//

import SwiftUI

struct FolderDetailView: View {
    let folder: Folder
   
    @State var showSettings = false
    @State var columns: [GridItem] = [.init(.flexible()), .init(.flexible())]
    @AppStorage("zoom.factor") var zoomFactor: Double = 2.0
    
    @EnvironmentObject var viewModel: PictureEntryViewModel
    
    var body: some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: columns) {
                ForEach(folder.entries) { entry in
                    EntryCell(folder: folder, entry: entry) {
                        
                    }
                }
            }
        }
        .onChange(of: zoomFactor, perform: { newValue in
            if zoomFactor > 4 {
                columns = [.init(.flexible())]
            } else {
                columns = [.init(.flexible()), .init(.flexible())]
            }
        })
        .navigationTitle(folder.fullName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                    
                    Button {
                        showSettings.toggle()
                    } label: {
                        Label("Appearance", systemImage: "sparkles")
                    }

                    Button(role: .destructive) {
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .tint(.white)
                }
            }
        }
        .presentModal(isPresented: $showSettings) {
            HomeSettingsView(showSettings: $showSettings)
        }
    }
}

struct FolderDetailView_Previews: PreviewProvider {
    static var previews: some View {
        FolderDetailView(folder: .init(id: UUID(), name: "fire", emoji: "🔥", entries: []))
    }
}
