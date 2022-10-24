//
//  ContentView.swift
//  Crate
//
//  Created by Mike Choi on 10/12/22.
//

import SwiftUI

final class PictureEntryViewModel: ObservableObject {
    lazy var relativeDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .short
        df.doesRelativeDateFormatting = true
        return df
    }()
    
    func image(for entry: PictureEntry) -> UIImage {
        ImageStorage.shared.loadImage(named: entry.modified ?? entry.original) ?? UIImage()
    }
    
    func name(for entry: PictureEntry) -> String {
        entry.name ?? "Untitled"
    }
    
    func dateString(for entry: PictureEntry) -> String {
        if let date = entry.date {
            return relativeDateFormatter.string(from: date)
        } else {
            return "Unknown"
        }
    }
}

struct HomeView: View {
    @State private var showingImagePicker = false
    @State private var showImageReviewModal = false
    @State private var imagesPayload: ImagesPayload?
    @Binding var detailPayload: DetailPayload?
    
    // MARK: - Core Data
    
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \PictureFolder.name, ascending: true)], animation: .default)
    var folders: FetchedResults<PictureFolder>

    // MARK: -
    
    @StateObject var viewModel = PictureEntryViewModel()
    
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
                
                Button {
                    showingImagePicker = true
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
                        .font(.system(size: 17, weight: .semibold, design: .default))
                        .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(imagesPayload: $imagesPayload)
        }
        .fullScreenCover(item: $imagesPayload) { payload in
            ImageReview(images: payload.images)
        }
    }
    
    @ViewBuilder
    func section(_ folder: Folder) -> some View {
        HStack(alignment: .center) {
            Text(folder.fullName)
                .font(.system(size: 16, weight: .semibold, design: .default))
                .foregroundColor(.white)
            
            Spacer()
            
            Button {
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundColor(.white)
                    .font(.system(size: 15, weight: .bold, design: .default))
            }
        }
        .padding(.vertical)
        
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHGrid(rows: [GridItem(.flexible())]) {
                ForEach(folder.entries) { entry in
                    Button {
                        detailPayload = DetailPayload(id: UUID(), folder: folder, detail: entry)
                    } label: {
                        VStack(alignment: .center, spacing: 6) {
                            Image(uiImage: viewModel.image(for: entry))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 200)
                            
                            VStack(alignment: .center, spacing: 4) {
                                Text(viewModel.name(for: entry))
                                    .font(.system(size: 16, weight: .semibold, design: .default))
                                    .foregroundColor(.white)
                                
                                Text(viewModel.dateString(for: entry))
                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
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
        HomeView(detailPayload: .constant(nil))
            .environment(\.managedObjectContext, DataController.preview.container.viewContext)
    }
}
