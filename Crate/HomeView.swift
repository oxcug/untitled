//
//  ContentView.swift
//  Crate
//
//  Created by Mike Choi on 10/12/22.
//

import SwiftUI
import FloatingPanel

struct HomeView: View {
    @State private var showingImagePicker = false
    @State private var showImageReviewModal = false
    @State private var imagesPayload: ImagesPayload?
    @Binding var detailPayload: DetailPayload?
    
    @StateObject var detailViewModel = ImageDetailViewModel()
    @StateObject var storage: FolderStorage = .shared
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                List {
                    ForEach(storage.folders) { folder in
                        section(folder)
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
                .environmentObject(storage)
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
                        detailPayload = DetailPayload(id: UUID(), folderName: folder.fullName, detail: entry)
                    } label: {
                        VStack(alignment: .leading, spacing: 12) {
                            Image(uiImage: entry.modified!)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 180)
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text(entry.name)
                                    .font(.system(size: 18, weight: .semibold, design: .default))
                                    .foregroundColor(.white)
                                
                                Text(entry.date.description)
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
    }
}
