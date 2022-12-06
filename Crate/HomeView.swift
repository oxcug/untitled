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
    @EnvironmentObject var inboxViewModel: InboxViewModel
    
    @AppStorage("active.icon") var activeIcon: AppIcon = .untitled

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                List {
                    if inboxViewModel.images.count > 0 {
                        inboxSection(images: inboxViewModel.images)
                    }
                    
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
            ImageReview(images: payload.images, entry: nil) {
                inboxViewModel.clearInbox()
            }
        }
        .presentFullScreenModal(item: $detailPayload) { payload in
            ImageDetailView(detailPayload: payload)
                .environment(\.managedObjectContext, DataController.shared.container.viewContext)
                .environmentObject(detailViewModel)
        }
        .task {
            inboxViewModel.loadInbox()
        }
    }
    
    @ViewBuilder
    func inboxSection(images: [InboxImage]) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            ZStack {
                ScrollView(.horizontal) {
                    LazyHStack {
                        ForEach(Array(images.enumerated()), id: \.self.element) { (idx, image) in
                            Image(uiImage: image.image)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(8)
                                .frame(height: 80)
                                .padding(.leading, idx == 0 ? 20 : 0)
                                .padding(.trailing, idx == images.count - 1 ? 20 : 0)
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
                    .allowsHitTesting(false)  // << now works !!
                
                Rectangle()
                    .fill(
                        LinearGradient(gradient: Gradient(stops: [
                            .init(color: Color(UIColor.systemBackground).opacity(0.01), location: 0),
                            .init(color: Color(UIColor.systemBackground), location: 1)
                        ]), startPoint: .leading, endPoint: .trailing)
                    ).frame(width: 20)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .allowsHitTesting(false)  // << now works !!
            }

            VStack(alignment: .leading) {
                let singular = images.count <= 1
                ZStack(alignment: .topLeading) {
                    (
                        Text(Image(systemName: "circle.fill")).foregroundColor(.red).font(.system(size: 12)).baselineOffset(3) +
                        Text(" You've got \(images.count) picture\(singular ? "" : "s") in your inbox").font(.system(size: 21, weight: .bold, design: .default))
                    )
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Button {
                    imagesPayload = .init(id: UUID(), images: images.map(\.image))
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(detailPayload: .dummy, showSettings: .constant(false), showVisualSettings: .constant(false))
            .environment(\.managedObjectContext, DataController.preview.container.viewContext)
    }
}
