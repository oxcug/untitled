//
//  ContentView.swift
//  untitled
//
//  Created by Mike Choi on 10/12/22.
//

import Combine
import SwiftUI
import FloatingPanel

struct EntryCell: View {
    let folder: Folder
    let entry: PictureEntry
    
    var didTap: () -> ()
    
    @AppStorage("show.labels") var showLabels = true
    @AppStorage("zoom.factor") var zoomFactor: Double = 4.0
    @EnvironmentObject var viewModel: PictureEntryViewModel
    
    var body: some View {
        Button {
            didTap()
        } label: {
            VStack(alignment: .center, spacing: 6) {
                Image(uiImage: viewModel.image(for: entry))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 50 * zoomFactor)
                
                if showLabels {
                    VStack(alignment: .center, spacing: 4) {
                        Text(viewModel.name(for: entry))
                            .font(.system(size: 16, weight: .semibold, design: .default))
                            .foregroundColor(.white)
                        
                        Text(viewModel.dateString(for: entry))
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .padding(.horizontal, showLabels ? 20 : 10)
        }
    }
}

struct HomeView: View {
    @State var detailPayload: DetailPayload = .dummy
    @Binding var showSettings: Bool
    @Binding var showVisualSettings: Bool
    
    @State var imagesPayload: ImagesPayload?
    @State var showingImagePicker = false
    @State var showImageReviewModal = false
    
    // MARK: - Core Data
    
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \PictureFolder.name, ascending: true)], animation: .default)
    var folders: FetchedResults<PictureFolder>
    
    // MARK: -
    
    @StateObject var viewModel = PictureEntryViewModel()
    @StateObject var panelDelegate = SettingsPanelDelegate()
    @StateObject var detailViewModel = PictureEntryDetailViewModel()
    
    @AppStorage("active.icon") var activeIcon: AppIcon = .untitled

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                List {
                    ForEach(folders) { folder in
                        section(Folder(coreDataObject: folder))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .navigationDestination(for: Folder.self) { folder in
                    FolderDetailView(folder: folder)
                        .environmentObject(viewModel)
                        .environmentObject(detailViewModel)
                }
                
                Button {
                    showingImagePicker = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 28, weight: .semibold, design: .default))
                        .foregroundColor(Color.white)
                        .padding()
                        .background(Circle().foregroundColor(activeIcon.color))
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("untitled.")
                        .font(.system(size: 18, weight: .bold, design: .default))
                        .foregroundColor(activeIcon.color)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showVisualSettings.toggle()
                    } label: {
                        Image(systemName: "eyes")
                            .foregroundColor(.bodyText)
                    }
                }
               
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showSettings.toggle()
                    } label: {
                        Image(systemName: "person.fill")
                            .foregroundColor(.bodyText)
                    }
                }
            }
            
        }
        .tint(.bodyText)
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(imagesPayload: $imagesPayload)
        }
        .fullScreenCover(item: $imagesPayload) { payload in
            ImageReview(images: payload.images, entry: nil)
        }
        .presentFullScreenModal(item: $detailPayload) { payload in
            ImageDetailView(detailPayload: payload)
                .environment(\.managedObjectContext, DataController.shared.container.viewContext)
                .environmentObject(detailViewModel)
        }
    }
    
    @ViewBuilder
    func section(_ folder: Folder) -> some View {
        NavigationLink(value: folder) {
            Text(folder.fullName)
                .modifier(SemiBoldBodyTextModifier())
                .padding(.vertical)
        }
        
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHGrid(rows: [GridItem(.flexible())]) {
                ForEach(folder.entries) { entry in
                    EntryCell(folder: folder, entry: entry) {
                        detailPayload = DetailPayload(id: UUID(), folder: folder, detail: entry)
                    }
                    .environmentObject(viewModel)
                }
            }
        }
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(detailPayload: .dummy, showSettings: .constant(false), showVisualSettings: .constant(false))
            .environment(\.managedObjectContext, DataController.preview.container.viewContext)
    }
}
