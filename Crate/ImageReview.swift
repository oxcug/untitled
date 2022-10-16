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
    @State var keyboardHeight: CGFloat = 0
    @FocusState var isNameFocused: Bool
    
    @EnvironmentObject var storage: FolderStorage
    @Environment(\.presentationMode) var presentationMode
    
    let toggleFeedback = UIImpactFeedbackGenerator(style: .rigid)
    let selectionFeedback = UISelectionFeedbackGenerator()
    var streams = Set<AnyCancellable>()
    
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
                   
                    HStack(alignment: .center) {
                        Text("Category")
                            .font(.system(size: 15, weight: .semibold, design: .default))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 15) {
                            if !viewModelManager.folders.isEmpty {
                                ForEach(viewModelManager.folders) { folder in
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
                    .listRowBackground(Color.black)
                    .padding(20)
                    
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
                        presentationMode.wrappedValue.dismiss()
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
        }
    }
}

struct ImageReviewasdf: View {
    let images: [UIImage]
    
    @StateObject var viewModelManager = ImageReviewManager()
    @State var progress = 1
    @State var keyboardHeight: CGFloat = 0
    @FocusState var isNameFocused: Bool
    
    @EnvironmentObject var storage: FolderStorage
    @Environment(\.presentationMode) var presentationMode
    
    let toggleFeedback = UIImpactFeedbackGenerator(style: .rigid)
    let selectionFeedback = UISelectionFeedbackGenerator()
    var streams = Set<AnyCancellable>()
    
    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ZStack(alignment: .bottom) {
                    ScrollView(.vertical) {
                        editor(size: proxy.size)
                            .offset(y: 15)
                    }.gesture(
                        DragGesture().onChanged { value in
                            isNameFocused = false
                        }
                    )
                }
            }
            .onReceive(Publishers.keyboardHeight) { height in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        self.keyboardHeight = height
                    }
                }
            }
            .onAppear {
                viewModelManager.setActiveViewModel(ImageReviewViewModel(image: images.first!))
            }
        }
    }
    
    @ViewBuilder
    func editor(size: CGSize) -> some View {
        VStack(spacing: 30) {
            ZStack(alignment: .bottomTrailing) {
                LazyHGrid(rows: [.init(.flexible())]) {
                    ForEach(images, id: \.description) { image in
                        let imageHeight = size.height * 0.6
                        let textFieldLocation = imageHeight + 55 + 150
                        let screenHeight = UIScreen.main.bounds.height
                        let padding = max(0, textFieldLocation - (screenHeight - keyboardHeight))
                        
                        ZStack {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(10)
                                .frame(width: 375, height: 360)
                            
                            ForEach(viewModelManager.textBoundingRects, id: \.debugDescription) { rect in
                                Rectangle()
                                    .foregroundColor(.red)
                                    .position(x: rect.minX, y: rect.minY)
                                    .frame(width: rect.width, height: rect.height)
                            }
                        }
                        .id(image.description)
                        
                    }
                    .onChange(of: progress) { newValue in
                        let idx = progress - 1
                        if idx == images.count {
                            presentationMode.wrappedValue.dismiss()
                        } else {
                            //                            scrollReader.scrollTo(viewModels[idx].payload.id)
                        }
                    }
                }
                
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        viewModelManager.toggleFocus()
                    }
                    
                    toggleFeedback.impactOccurred()
                } label: {
                    ZStack {
                        Circle().foregroundColor(Color.black.opacity(0.15))
                            .frame(width: 45, height: 45)
                        
                        Image(systemName: viewModelManager.focus == .person ? "person.fill" : "textformat")
                            .font(.system(size: 22, weight: .semibold, design: .default))
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
                .padding(.bottom)
            }
            
            VStack(spacing: 20) {
                GeometryReader { proxy in
                    TextField("Name this...", text: $viewModelManager.name)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal)
                        .focused($isNameFocused)
                }
            }
        }
    }
}

struct ImageReview_Previews: PreviewProvider {
    static var previews: some View {
        ImageReview(images: [UIImage(named: "porter.jpeg")!])
            .environmentObject(FolderStorage.shared)
    }
}
