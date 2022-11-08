//
//  FolderDetailView.swift
//  Crate
//
//  Created by Mike Choi on 11/8/22.
//

import SwiftUI

struct FolderDetailView: View {
    let folder: Folder
  
    @State var title = ""
    @State var showSettings = false
    @State var editFolderName = false
    @State var columns: [GridItem] = [.init(.flexible()), .init(.flexible())]
    
    @State var detailPayload: DetailPayload = .dummy

    @AppStorage("zoom.factor") var zoomFactor: Double = 2.0
    @EnvironmentObject var viewModel: PictureEntryViewModel
    @EnvironmentObject var detailViewModel: PictureEntryDetailViewModel
    
    var body: some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: columns) {
                ForEach(folder.entries) { entry in
                    EntryCell(folder: folder, entry: entry) {
                        detailPayload = DetailPayload(id: UUID(), folder: folder, detail: entry)
                    }
                }
            }
        }
        .task {
            title = folder.fullName
        }
        .onChange(of: zoomFactor, perform: { newValue in
            if zoomFactor > 4 {
                columns = [.init(.flexible())]
            } else {
                columns = [.init(.flexible()), .init(.flexible())]
            }
        })
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .default))
                    .foregroundColor(.white)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        editFolderName.toggle()
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
        .presentFullScreenModal(item: $detailPayload) { payload in
            ImageDetailView(detailPayload: payload)
                .environmentObject(detailViewModel)
        }
        .sheet(isPresented: $editFolderName) {
            NavigationStack {
                FolderCreationView(folder: folder) {
                    title = $0
                }
            }
        }
    }
}

struct FolderDetailView_Previews: PreviewProvider {
    static var previews: some View {
        FolderDetailView(folder: .init(id: UUID(), name: "fire", emoji: "🔥", entries: [], coreDataObject: nil))
    }
}
