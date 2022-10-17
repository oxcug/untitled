//
//  ImageReview.swift
//  Crate
//
//  Created by Mike Choi on 10/12/22.
//

import Combine
import SwiftUI

struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}

extension View {
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometryProxy in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometryProxy.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
}

struct ImageReview: View {
    let images: [UIImage]
    
    @StateObject var viewModelManager = ImageReviewManager()
    @State var progress = 1
    @FocusState var isNameFocused: Bool
    
    @EnvironmentObject var storage: FolderStorage
    @Environment(\.dismiss) private var dismiss
    
    let toggleFeedback = UIImpactFeedbackGenerator(style: .rigid)
    let selectionFeedback = UISelectionFeedbackGenerator()
    var streams = Set<AnyCancellable>()
    
    @State var showFolderSelection = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                List {
                    ZStack(alignment: .topLeading) {
                        let imageHeight = UIScreen.main.bounds.size.height * 0.7
                        
                        Image(uiImage: images.first!)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(10)
                            .scaledToFit()
                            .frame(height: imageHeight)
                            .readSize { size in
                                viewModelManager.setActiveViewModel(ImageReviewViewModel(image: images.first!))
                                viewModelManager.requestForProcessing(imageSize: size)
                            }
                        
                        ForEach(viewModelManager.textBoundingRects, id: \.debugDescription) { rect in
                            Rectangle()
                                .foregroundColor(.red.opacity(0.4))
                                .position(x: rect.midX, y: rect.midY)
                                .frame(width: rect.width, height: rect.height)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.black)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                  
                    Button {
                        showFolderSelection = true
                    } label: {
                        HStack(alignment: .center) {
                            Text("Category")
                                .font(.system(size: 15, weight: .semibold, design: .default))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 15) {
                                if !viewModelManager.folders.isEmpty {
                                    ForEach(Array(viewModelManager.folders).sorted()) { folder in
                                        Text(folder.fullName)
                                            .font(.system(size: 12, weight: .semibold, design: .default))
                                            .foregroundColor(.white)
                                            .padding(12)
                                            .background(RoundedRectangle(cornerRadius: 20).foregroundColor(.gray).opacity(0.2))
                                    }
                                } else {
                                    Text("No selection")
                                        .font(.system(size: 12, weight: .semibold, design: .default))
                                        .foregroundColor(.white)
                                        .padding(12)
                                        .background(RoundedRectangle(cornerRadius: 20).foregroundColor(.gray).opacity(0.2))
                                }
                            }
                        }
                    }
                    .listRowBackground(Color.black)
                    .padding(.vertical, 20)
                    
                    Spacer(minLength: 100)
                        .listRowBackground(Color.black)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                
                VStack(spacing: 0) {
                    Separator()
                        .frame(maxWidth: .infinity)
                    
                    ZStack {
                        Button {
                            progress += 1
                        } label: {
                            Text("finishing touches")
                                .font(.system(size: 15, weight: .semibold, design: .default))
                                .foregroundColor(Color(uiColor: .black))
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(RoundedRectangle(cornerRadius: 10).foregroundColor(Color(uiColor: .white)))
                        }
                        .padding(20)
                        .background(Rectangle().foregroundColor(.black))
                    }
                }
            }
            .padding(.top, 10)
            .background(Color.black)
            .edgesIgnoringSafeArea(.bottom)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 15, weight: .semibold, design: .default))
                            .foregroundColor(.gray)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("\(progress) of \(images.count)")
                        .font(.system(size: 15, weight: .semibold, design: .default))
                        .foregroundColor(.white)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showFolderSelection) {
                NavigationStack {
                    FolderSelectionView(folders: $viewModelManager.folders)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct ImageReview_Previews: PreviewProvider {
    static var previews: some View {
        ImageReview(images: [UIImage(named: "porter.jpeg")!])
            .environmentObject(FolderStorage.shared)
    }
}
