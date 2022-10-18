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

struct SingleImageReview: View {
    @State private var keyboardHeight: CGFloat = 0
    
    @EnvironmentObject var viewModel: ImageReviewViewModel
    @FocusState var isNameFocused: Bool
    @Environment(\.dismiss) private var dismiss
    
    let toggleFeedback = UIImpactFeedbackGenerator(style: .rigid)
    let selectionFeedback = UISelectionFeedbackGenerator()
    var streams = Set<AnyCancellable>()
    
    @State var showFolderSelection = false
    
    var body: some View {
        ScrollViewReader { scrollViewProxy in
            List {
                imagePreview
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.black)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0))
                    .id(0)
                
                TextField("Give it a name...", text: $viewModel.name)
                    .font(.system(size: 20, weight: .semibold, design: .default))
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .multilineTextAlignment(.center)
                    .id(1)
                
                categoryRow
                    .listRowBackground(Color.black)
                    .id(2)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.system(size: 15, weight: .semibold, design: .default))
                        .foregroundColor(.white)
                   
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(viewModel.selectedTextBoundingBoxes) { box in
                            Text(box.string)
                                .font(.system(size: 15, weight: .regular, design: .default))
                        }
                    }
                }
                
                Spacer(minLength: 100 + keyboardHeight)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.black)
                    .id(3)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.immediately)
            .sheet(isPresented: $showFolderSelection) {
                NavigationStack {
                    FolderSelectionView(selectedFolder: $viewModel.folder)
                }
            }
            .onReceive(Publishers.keyboardHeight) { height in
                withAnimation(.easeInOut(duration: 0.15)) {
                    self.keyboardHeight = height
                    scrollViewProxy.scrollTo(1, anchor: .top)
                }
            }
        }
    }
    
    var imagePreview: some View {
        ZStack(alignment: .topLeading) {
            let imageHeight = UIScreen.main.bounds.size.height * 0.65
            
            Image(uiImage: viewModel.image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .cornerRadius(10)
                .scaledToFit()
                .opacity(0.5)
                .frame(height: imageHeight)
                .readSize { size in
                    viewModel.requestForProcessing(imageSize: size)
                }
            
            if let segmented = viewModel.segmentedImage {
                Button {
                    viewModel.includeSegmentedImage.toggle()
                    selectionFeedback.selectionChanged()
                } label: {
                    Image(uiImage: viewModel.includeSegmentedImage ? segmented.active : segmented.inactive)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: imageHeight)
                        .opacity(viewModel.includeSegmentedImage ? 1 : 0.8)
                }
                .buttonStyle(.plain)
                .aspectRatio(contentMode: .fit)
                .frame(height: imageHeight)
            }
            
            ForEach(viewModel.textBoundingBoxes) { box in
                let rect = box.box
                let isSelected = viewModel.selectedTextBoundingBoxes.contains(box)
                
                Button {
                    selectionFeedback.selectionChanged()
                    viewModel.didTapBoundingBox(box)
                } label: {
                    RoundedRectangle(cornerRadius: 4)
                        .foregroundColor(.white.opacity(isSelected ? 0.5 : 0.3))
                        .buttonBorderShape(.roundedRectangle(radius: 4))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.blue, lineWidth: isSelected ? 2 : 0)
                        )
                }
                .buttonStyle(.plain)
                .position(x: rect.midX, y: rect.midY)
                .frame(width: rect.width, height: rect.height + 4)
            }
        }
    }
    
    var categoryRow: some View {
        Button {
            showFolderSelection = true
        } label: {
            HStack(alignment: .center) {
                Text("Folder")
                    .font(.system(size: 15, weight: .semibold, design: .default))
                    .foregroundColor(.white)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 15) {
                    if let selectedFolder = viewModel.folder {
                        Text(selectedFolder.fullName)
                            .font(.system(size: 12, weight: .semibold, design: .default))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 20).foregroundColor(.gray).opacity(0.2))
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
    }
}

struct ImageReview: View {
    let images: [UIImage]
    
    @State var selectedPage: Int = 0
    @State var isKeyboardVisible = false
    @State var errorMessage = ""
    @StateObject var viewModelManager = ImageReviewManager()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                TabView(selection: $selectedPage) {
                    ForEach($viewModelManager.viewModels) { $viewModel in
                        SingleImageReview()
                            .environmentObject(viewModel)
                            .tag(viewModel.pageNumber)
                    }
                }
//                .tabViewStyle(.page(indexDisplayMode: .never))
                
                nextFooter
                    .background(Color.black, ignoresSafeAreaEdges: .bottom)
            }
            .toolbar {
                ToolbarCancelButton()
                
                ToolbarItem(placement: .principal) {
                    Text("\(selectedPage + 1) of \(images.count)")
                        .font(.system(size: 15, weight: .semibold, design: .default))
                        .foregroundColor(.white)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
        }
        .onAppear {
            viewModelManager.createViewModels(images: images)
        }
    }
    
    var nextFooter: some View {
        VStack(spacing: 0) {
            Separator()
                .frame(maxWidth: .infinity)
            
            HStack {
                Text(errorMessage)
                    .font(.system(size: 14, weight: .semibold, design: .default))
                    .foregroundColor(.red)
                
                Spacer()
                
                let lastOne = selectedPage == images.count - 1
                
                Button {
                    if lastOne {
                        if viewModelManager.current.folder == nil {
                            showErrorMessage()
                        } else {
                            viewModelManager.save()
                            dismiss()
                        }
                    } else {
                        selectedPage += 1
                        viewModelManager.selectViewModel(idx: selectedPage)
                    }
                } label: {
                    Text(lastOne ? "Finish" : "Next")
                        .font(.system(size: 14, weight: .semibold, design: .default))
                        .foregroundColor(Color(uiColor: .black))
                        .frame(width: 50)
                        .padding(8)
                        .background(Capsule(style: .circular).foregroundColor(Color(uiColor: .white)))
                }
                .background(Rectangle().foregroundColor(.black))
            }
            .padding(.top, 15)
            .padding(.horizontal, 15)
            .padding(.bottom, isKeyboardVisible ? 15 : 0)
        }
        .onReceive(Publishers.keyboardWillBeVisible) { isVisible in
            withAnimation(.easeInOut(duration: 0.1)) {
                isKeyboardVisible = isVisible
            }
        }
    }
    
    func showErrorMessage() {
        withAnimation(.easeInOut(duration: 0.15)) {
            errorMessage = "❗Select Folder"
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.easeInOut(duration: 0.15)) {
                    errorMessage = ""
                }
            }
        }
    }
}

struct ImageReview_Previews: PreviewProvider {
    static var previews: some View {
        ImageReview(images: [UIImage(named: "represent.jpeg")!])
    }
}
