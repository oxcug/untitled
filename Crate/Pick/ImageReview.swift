//
//  ImageReview.swift
//  untitled
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
    @State var showFolderSelection = false
    @State var keyboardHeight: CGFloat = 0
    @FocusState var isNameFocused: Bool
    
    @EnvironmentObject var viewModel: ImageReviewViewModel
    @Environment(\.dismiss) private var dismiss
    
    let titleFeedback = UIImpactFeedbackGenerator(style: .heavy)
    let selectionFeedback = UISelectionFeedbackGenerator()
    var streams = Set<AnyCancellable>()
    
    var body: some View {
        ScrollViewReader { scrollViewProxy in
            List {
                imagePreview
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0))
                    .id(0)
                
                TextField("Give it a name...", text: $viewModel.name)
                    .font(.system(size: 20, weight: .semibold, design: .default))
                    .foregroundColor(.bodyText)
                    .padding(.vertical, 8)
                    .multilineTextAlignment(.center)
                    .id(1)
                
                categoryRow
                    .id(2)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .modifier(SemiBoldBodyTextModifier())
                }
                
                Spacer(minLength: 100 + keyboardHeight)
                    .listRowSeparator(.hidden)
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
                .zIndex(0)
            }
            
            ForEach(viewModel.textBoundingBoxes) { box in
                let rect = box.box
                let isTitle = (viewModel.titleBox == box)
                
                Button {
                    viewModel.didTapBoundingBox(box)
                    
                    if viewModel.titleBox != nil {
                        titleFeedback.impactOccurred()
                    } else {
                        selectionFeedback.selectionChanged()
                    }
                } label: {
                    RoundedRectangle(cornerRadius: 4)
                        .foregroundColor(.white.opacity(isTitle ? 0.5 : 0.3))
                        .background(
                            Rectangle()
                                .foregroundColor(.clear)
                                .background(RoundedCorners(color: (isTitle ? Color.orange : Color.blue),
                                                           tl: 4,
                                                           tr: 4,
                                                           bl: 4,
                                                           br: isTitle ? 0 : 4))
                                .opacity(isTitle ? 1 : 0)
                        )
                        .overlay(
                            Text("TITLE")
                                .font(.system(size: 9, weight: .bold, design: .default))
                                .foregroundColor(.white)
                                .padding(3)
                                .background(FilledRoundedCorners(color: Color.orange,
                                                                 tl: 0,
                                                                 tr: 0,
                                                                 bl: 4,
                                                                 br: 4))
                                .opacity(isTitle ? 1 : 0)
                                .offset(x: (box.box.width - 31) / 2, y: box.box.height + 4)
                        )
                }
                .zIndex(isTitle ? 2 : 0)
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
                    .modifier(SemiBoldBodyTextModifier())
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 15) {
                    if let selectedFolder = viewModel.folder {
                        Text(selectedFolder.fullName)
                            .font(.system(size: 12, weight: .semibold, design: .default))
                            .foregroundColor(.bodyText)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 20).foregroundColor(.gray).opacity(0.2))
                    } else {
                        Text("No selection")
                            .font(.system(size: 12, weight: .semibold, design: .default))
                            .foregroundColor(.bodyText)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 20).foregroundColor(.gray).opacity(0.2))
                    }
                }
            }
        }
    }
}

struct ImageReview: View {
    let images: [UIImage]?
    let detail: DetailPayload?
    
    @State var title: String = ""
    @State var selectedPage: Int = 0
    @State var isKeyboardVisible = false
    @State var errorMessage = ""
    @StateObject var viewModelManager = ImageReviewManager()
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) var viewContext
    
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
                
                nextFooter
            }
            .toolbar {
                ToolbarCancelButton()
                
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold, design: .default))
                        .foregroundColor(.bodyText)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            if let images = images {
                title = "\(selectedPage + 1) of \(images.count)"
                viewModelManager.createViewModels(images: images)
            } else if let detail = detail {
                title = "Edit"
                viewModelManager.setupEditMode(detail: detail)
            }
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
                
                let isLastOne = (selectedPage == (images?.count ?? 1) - 1)
                
                Button {
                    save(isLastOne)
                } label: {
                    Text(isLastOne ? "Finish" : "Next")
                        .font(.system(size: 14, weight: .semibold, design: .default))
                        .foregroundColor(Color(uiColor: .secondarySystemBackground))
                        .frame(width: 50)
                        .padding(8)
                        .background(Capsule(style: .circular).foregroundColor(.bodyText))
                }
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
    
    func save(_ isLastOne: Bool) {
        if viewModelManager.current.folder == nil {
            showErrorMessage()
            return
        }
        
        if isLastOne {
            Task {
                await viewModelManager.save(viewContext: viewContext)
                dismiss()
            }
        } else {
            selectedPage += 1
            viewModelManager.selectViewModel(idx: selectedPage)
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
        ImageReview(images: [UIImage(named: "represent.jpeg")!], detail: nil)
            .preferredColorScheme(.light)
            .environment(\.managedObjectContext, DataController.preview.container.viewContext)
        
        ImageReview(images: [UIImage(named: "represent.jpeg")!], detail: nil)
            .preferredColorScheme(.dark)
            .environment(\.managedObjectContext, DataController.preview.container.viewContext)
    }
}
