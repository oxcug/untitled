//
//  FolderDetailView.swift
//  untitled
//
//  Created by Mike Choi on 11/8/22.
//

import SwiftUI

struct FolderDetailView: View {
    let folder: Folder
  
    @State var title = ""
    @State var showSettings = false
    @State var editFolderName = false
    @State var showDeletionConfirmation = false
    @State var columns: [GridItem] = [.init(.flexible()), .init(.flexible())]
    
    @State var detailPayload: DetailPayload = .dummy

    @AppStorage("zoom.factor") var zoomFactor: Double = 2.0
    @EnvironmentObject var viewModel: PictureEntryViewModel
    @EnvironmentObject var detailViewModel: PictureEntryDetailViewModel
    
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.dismiss) var dismiss
    
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
            switch newValue {
                case let x where (0...3).contains(x):
                    columns = Array(repeating: .init(.flexible()), count: 3)
                case let x where (3...5).contains(x):
                    columns = Array(repeating: .init(.flexible()), count: 2)
                default:
                    columns = Array(repeating: .init(.flexible()), count: 1)
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
                        showDeletionConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .tint(.white)
                }
            }
        }
        .presentModal(isPresented: $showSettings, height: 200) {
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
        .alert(isPresented: $showDeletionConfirmation) {
            Alert(title: Text("Delete \"\(folder.fullName)\"?"), primaryButton: .cancel(), secondaryButton: .destructive(Text("Delete")) {
                if let cd = folder.coreDataObject {
                    viewContext.delete(cd)
                    try? viewContext.save()
                    dismiss()
                }
            })
        }
    }
}

struct FolderDetailView_Previews: PreviewProvider {
    static var previews: some View {
        FolderDetailView(folder: .init(id: UUID(), name: "fire", emoji: "🔥", entries: [], coreDataObject: nil))
    }
}
