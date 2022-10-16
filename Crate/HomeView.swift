//
//  ContentView.swift
//  Crate
//
//  Created by Mike Choi on 10/12/22.
//

import SwiftUI
import FloatingPanel

final class SavedMapPanelLayout: FloatingPanelLayout {
    var initialState: FloatingPanelState {
        .hidden
    }
    
    var position: FloatingPanelPosition {
        .bottom
    }
    
    var anchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] {
        return [
            .full: FloatingPanelLayoutAnchor(absoluteInset: 0.0, edge: .top, referenceGuide: .superview),
            .hidden: FloatingPanelLayoutAnchor(absoluteInset: 0, edge: .bottom, referenceGuide: .superview)
        ]
    }
}

final class DetailFloatingPanelDelegate: FloatingPanelControllerDelegate, ObservableObject {
    func floatingPanel(_ fpc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout {
        fpc.surfaceView.grabberHandle.isHidden = true
        return SavedMapPanelLayout()
    }
    
    func floatingPanel(_ fpc: FloatingPanelController, shouldRemoveAt location: CGPoint, with velocity: CGVector) -> Bool {
        return false
    }
}

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)], animation: .default)
    private var items: FetchedResults<Item>
    
    @State private var showingImagePicker = false
    @State private var showImageReviewModal = false
    @State private var imagesPayload: ImagesPayload?
    @State var displayEntry: Entry?
    @State var folderName = ""
    
    @StateObject var panelDelegate = DetailFloatingPanelDelegate()
    @StateObject var detailViewModel = ImageDetailViewModel()
     @EnvironmentObject var storage: FolderStorage
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                List {
                    ForEach(storage.folders) { folder in
                        section(folder)
                    }
                }
                .listStyle(.plain)
                
                Button {
                    showingImagePicker = true
//                    displayEntry = .init(id: UUID(), name: "asdf", date: Date(), original: UIImage(named: "modified.png")!, modified: nil, colors: [])
                    folderName = "⭐ Favorites"
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 28, weight: .semibold, design: .default))
                        .foregroundColor(Color.white)
                        .padding()
                        .background(Circle().foregroundColor(.blue))
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Crate")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(imagesPayload: $imagesPayload)
        }
        .floatingPanel(delegate: panelDelegate) { proxy in
            ImageDetailView(proxy: proxy, folderName: $folderName, entry: $displayEntry)
                .environmentObject(detailViewModel)
        }
        .floatingPanelSurfaceAppearance(.phone)
        .floatingPanelContentMode(.fitToBounds)
        .floatingPanelContentInsetAdjustmentBehavior(.never)
        .fullScreenCover(item: $imagesPayload) { payload in
            ImageReview(images: payload.images)
                .environmentObject(storage)
        }
    }
    
    @ViewBuilder
    func section(_ folder: Folder) -> some View {
        Text(folder.fullName)
            .font(.system(size: 22, weight: .semibold, design: .default))
            .padding(.top, 8)
        
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHGrid(rows: [GridItem(.flexible())]) {
                ForEach(folder.entries) { entry in
                    Button {
                        folderName = folder.fullName
                        displayEntry = entry
                    } label: {
                        VStack(alignment: .leading, spacing: 12) {
                            Image(uiImage: entry.modified!)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 220)
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text(entry.name)
                                    .font(.system(size: 18, weight: .semibold, design: .default))
                                
                                Text(entry.date.description)
                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10)
                            .foregroundColor(Color(uiColor: .systemBackground)).shadow(radius: 0.4))
                        .padding(.leading, 20)
                    }
                }
            }
        }
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(FolderStorage.shared)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
