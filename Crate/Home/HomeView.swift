//
//  ContentView.swift
//  untitled
//
//  Created by Mike Choi on 10/12/22.
//

import Combine
import SwiftUI
import FloatingPanel
import Kingfisher

struct EntryCell: View {
    let folder: Folder
    let entry: PictureEntry
    
    var didTap: () -> ()
    
    @AppStorage("show.labels") var showLabels = true
    @AppStorage("zoom.factor") var zoomFactor: Double = 4.0
    @EnvironmentObject var viewModel: HomeViewModel
    
    var body: some View {
        Button {
            didTap()
        } label: {
            VStack(alignment: .center, spacing: 6) {
                KFImage(ImageStorage.shared.url(for: entry))
                    .fade(duration: 0.15)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 50 * zoomFactor)
                    .cornerRadius(1.5 * zoomFactor)
                
                if showLabels {
                    VStack(alignment: .center, spacing: 4) {
                        Text(viewModel.name(for: entry))
                            .font(.system(size: 14, weight: .semibold, design: .default))
                            .foregroundColor(Color(uiColor: .label))
                        
                        Text(viewModel.dateString(for: entry))
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(Color(uiColor: .label).opacity(0.5))
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
    
    @State var pickerPayload: PHPickerPayload = .init(id: .init(), results: [])
    @State var assetPackage: PickedAssetPackage?
    @State var showingImagePicker = false
    @State var showImageReviewModal = false
    @State var showTutorial = false
    
    // MARK: - Core Data
    
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \PictureFolder.name, ascending: true)], animation: .default)
    var folders: FetchedResults<PictureFolder>
    
    // MARK: -
    
    @StateObject var viewModel = HomeViewModel()
    @StateObject var panelDelegate = SettingsPanelDelegate()
    @StateObject var detailViewModel = PictureEntryDetailViewModel()
    @EnvironmentObject var inboxViewModel: InboxViewModel
    
    @AppStorage("active.icon") var activeIcon: AppIcon = .untitled

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                List {
                    if !inboxViewModel.imageURLs.isEmpty {
                        inboxSection(urls: inboxViewModel.imageURLs)
                    }
                    
                    if folders.isEmpty {
                        emptyView
                    } else {
                        ForEach(folders) { folder in
                            section(Folder(coreDataObject: folder))
                        }
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
                        .foregroundColor(Color(uiColor: .systemBackground))
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
                        Image(systemName: "magnifyingglass")
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
            ImagePicker(pickerPayload: $pickerPayload)
        }
        .sheet(isPresented: $showTutorial) {
            NavigationStack {
                TutorialView()
            }
        }
        .fullScreenCover(item: $assetPackage) { package in
            ImageReview(sources: package.sources, entry: nil) {
                inboxViewModel.clearInbox()
            }
        }
        .presentFullScreenModal(item: $detailPayload) { payload in
            ImageDetailView(detailPayload: payload)
                .environment(\.managedObjectContext, DataController.shared.container.viewContext)
                .environmentObject(detailViewModel)
        }
        .task {
            inboxViewModel.loadInboxThumbnails()
        }
        .onChange(of: pickerPayload) { payload in
            if !payload.results.isEmpty {
                viewModel.loadAssetDetails(pickerPayload: pickerPayload) {
                    self.assetPackage = $0
                }
            }
        }
        .overlay(
            ProgressView()
                .progressViewStyle(.circular)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ultraThinMaterial.opacity(0.8), in: Rectangle())
                .edgesIgnoringSafeArea([.top, .bottom])
                .opacity(viewModel.fetchingAssets ? 1 : 0)
        )
    }
    
    var emptyView: some View {
        VStack(spacing: 12) {
            Text("emptiness.")
                .font(.system(size: 14, weight: .semibold, design: .default))
            
            Text("now go fill it with your hopes and inspirations.")
                .font(.system(size: 14, weight: .semibold, design: .default))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                showTutorial = true
            } label: {
                Text("show me show")
                    .underline()
                    .font(.system(size: 14, weight: .semibold, design: .default))
                    .foregroundColor(activeIcon.color)
            }
        }
        .listRowSeparator(.hidden)
        .buttonStyle(.plain)
        .frame(height: UIScreen.main.bounds.height * 0.5)
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    @ViewBuilder
    func inboxThumbnailCarousel(urls: [URL]) -> some View {
        ZStack {
            ScrollView(.horizontal) {
                LazyHStack {
                    ForEach(Array(urls.enumerated()), id: \.self.element) { (idx, url) in
                        KFImage(url)
                            .placeholder { _ in
                                RoundedRectangle(cornerRadius: 8)
                                    .foregroundColor(.gray.opacity(0.3))
                            }
                            .downsampling(size: .init(width: 0, height: 80))
                            .fade(duration: 0.2)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(8)
                            .frame(height: 80)
                            .padding(.leading, idx == 0 ? 20 : 0)
                            .padding(.trailing, idx == urls.count - 1 ? 20 : 0)
                    }
                }
            }
            .scrollIndicators(.hidden)
            
            Rectangle()
                .fill(
                    LinearGradient(gradient: Gradient(stops: [
                        .init(color: Color(UIColor.systemBackground).opacity(0.01), location: 0),
                        .init(color: Color(UIColor.systemBackground), location: 1)
                    ]), startPoint: .trailing, endPoint: .leading)
                ).frame(width: 20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .allowsHitTesting(false)
            
            Rectangle()
                .fill(
                    LinearGradient(gradient: Gradient(stops: [
                        .init(color: Color(UIColor.systemBackground).opacity(0.01), location: 0),
                        .init(color: Color(UIColor.systemBackground), location: 1)
                    ]), startPoint: .leading, endPoint: .trailing)
                ).frame(width: 20)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .allowsHitTesting(false)
        }
    }
    
    @ViewBuilder
    func inboxSection(urls: [URL]) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            inboxThumbnailCarousel(urls: urls)

            VStack(alignment: .leading) {
                let actualCount = inboxViewModel.imageURLs.count
                let singular = (actualCount <= 1)
                ZStack(alignment: .topLeading) {
                    (
                        Text(Image(systemName: "circle.fill")).foregroundColor(.red).font(.system(size: 12)).baselineOffset(3) +
                        Text(" You've got \(actualCount) picture\(singular ? "" : "s") in your inbox").font(.system(size: 21, weight: .bold, design: .default))
                    )
                    .fixedSize(horizontal: false, vertical: true)
                }
                
                Button {
                    assetPackage = .init(id: .init(), sources: inboxViewModel.imageURLs)
                } label: {
                    Text("Review")
                        .font(.system(size: 18, weight: .bold, design: .default))
                        .foregroundColor(Color(uiColor: .systemBackground))
                        .padding()
                        .padding(.horizontal, 12)
                        .background(activeIcon.color)
                        .buttonBorderShape(.capsule)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .listRowSeparator(.hidden)
        .padding(.top, 5)
        .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 0, trailing: 0))
        .buttonStyle(.plain)
        
        Rectangle()
            .frame(height: 10)
            .foregroundColor(Color(uiColor: .secondarySystemBackground))
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            .background(.red)
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

struct HomeView_Previews: PreviewProvider {
    @StateObject static var inboxViewModel = InboxViewModel()
    
    static var previews: some View {
        HomeView(detailPayload: .dummy, showSettings: .constant(false), showVisualSettings: .constant(false))
            .environmentObject(inboxViewModel)
            .environment(\.managedObjectContext, DataController.preview.container.viewContext)
    }
}
