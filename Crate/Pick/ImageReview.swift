//
//  ImageReview.swift
//  untitled
//
//  Created by Mike Choi on 10/12/22.
//

import Combine
import SwiftUI
import Kingfisher

struct SingleImageReview: View {
    @State var showFolderSelection = false
    @State var keyboardHeight: CGFloat = 0
    @FocusState var isNameFocused: Bool
    @FocusState var isDescriptionFocused: Bool
    
    @EnvironmentObject var viewModel: ImageReviewViewModel
    @Environment(\.dismiss) private var dismiss
    
    let titleFeedback = UIImpactFeedbackGenerator(style: .heavy)
    let selectionFeedback = UISelectionFeedbackGenerator()
    var streams = Set<AnyCancellable>()
    
    var body: some View {
        ScrollViewReader { scrollViewProxy in
            List {
                ZStack(alignment: .center) {
                    imagePreview
                                    
                    if !viewModel.isFinishedProcessing {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .controlSize(.large)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0))

                TextField("untitled.", text: $viewModel.name)
                    .font(.system(size: 20, weight: .semibold, design: .default))
                    .foregroundColor(.bodyText)
                    .padding(.vertical, 8)
                    .multilineTextAlignment(.center)
                    .focused($isNameFocused)
                    .id(1)
                
                categoryRow
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .modifier(SemiBoldBodyTextModifier())
                    
                    TextField("So descriptive...", text: $viewModel.description, axis: .vertical)
                        .lineLimit(10)
                }
                .id(2)
                
                Spacer(minLength: 120 + keyboardHeight)
                    .listRowSeparator(.hidden)
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
                if height > 0 {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        scrollViewProxy.scrollTo(isNameFocused ? 1 : 2, anchor: .init(x: 0, y: UIScreen.main.bounds.size.height - keyboardHeight))
                    }
                }
                
                self.keyboardHeight = height
            }
        }
        .task {
            Task {
                await viewModel.loadImage(maxSize: .init(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.size.height * 0.6))
                await viewModel.preprocess()
            }
        }
    }
    
    var imagePreview: some View {
        ZStack(alignment: .topLeading) {
            ZStack {
                Image(uiImage: viewModel.originalImage ?? UIImage())
                    .resizable()
                    .cornerRadius(10)
                    .scaledToFit()
                    .opacity(viewModel.didSelectSegmentedImage ? 0.55 : 0.9)
                    .frame(height: viewModel.imageSize.height)

                if let segmented = viewModel.segmentedImage {
                    Image(uiImage: viewModel.didSelectSegmentedImage ? segmented.active : segmented.inactive )
                        .resizable()
                        .scaledToFit()
                        .frame(height: viewModel.imageSize.height)
                }
            }
            .transition(.opacity)
             
            Rectangle()
                .frame(width: viewModel.tappableBounds?.width ?? 0, height: viewModel.tappableBounds?.height ?? 0)
                .offset(x: viewModel.tappableBounds?.minX ?? 0, y: viewModel.tappableBounds?.minY ?? 0)
                .foregroundColor(Color.black.opacity(0.00001))
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.didSelectSegmentedImage.toggle()
                    }
                    selectionFeedback.selectionChanged()
                }
            
            textBoxes
        }
        .transition(.opacity)
        .frame(height: viewModel.imageSize.height < viewModel.imageSize.width ? viewModel.imageSize.height : UIScreen.main.bounds.height * 0.6)
    }
    
    var textBoxes: some View {
        ZStack(alignment: .topLeading) {
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
                        .foregroundColor(.white.opacity(isTitle ? 0.6 : 0.3))
                        .background(
                            Rectangle()
                                .foregroundColor(.clear)
                                .background(RoundedCorners(color: (isTitle ? Color.orange : Color.blue.opacity(0.3)),
                                                           tl: 4,
                                                           tr: 4,
                                                           bl: 4,
                                                           br: isTitle ? 0 : 4))
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
                                .position(x: (box.box.width - 31) / 2, y: box.box.height + 4)
                        )
                }
                .zIndex(isTitle ? 50 : 40)
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
    let sources: [DataRetrievable]
    let entry: EntryEntity?
    var didDismiss: (() -> ())?
    
    @State var title: String = ""
    @State var selectedPage: Int = 0
    @State var isKeyboardVisible = false
    @State var errorMessage = ""
    @State var isFinalizingSave = false
    
    @StateObject var viewModelManager = ImageReviewManager()
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) var viewContext
    
    let nextFeedback = UIImpactFeedbackGenerator(style: .rigid)
    
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
                ToolbarCancelButton {
                }
                
                ToolbarItem(placement: .principal) {
                    Text((entry == nil) ? "\(selectedPage + 1) of \(sources.count)" : "edit")
                        .font(.system(size: 15, weight: .semibold, design: .default))
                        .foregroundColor(.bodyText)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            if let entry = entry {
                viewModelManager.setupEditMode(entry: entry)
            } else {
                viewModelManager.createViewModels(sources: sources)
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
                
                let isLastOne = (selectedPage == (sources.count) - 1)
                
                Button {
                    nextFeedback.impactOccurred()
                    queueSave(isLastOne)
                } label: {
                    if viewModelManager.hasPendingSaveOperations {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(Color(uiColor: .secondarySystemBackground))
                    } else {
                        Text(isLastOne ? "finish" : "next")
                            .font(.system(size: 14, weight: .semibold, design: .default))
                            .foregroundColor(Color(uiColor: .secondarySystemBackground))
                    }
                }
                .frame(width: 50, height: 20)
                .padding(8)
                .background(Capsule(style: .circular).foregroundColor(.bodyText))

            }
            .padding(.top, 15)
            .padding(.horizontal, 15)
            .padding(.bottom, isKeyboardVisible ? 15 : 0)
        }
        .background(Color(uiColor: .secondarySystemBackground))
        .onReceive(Publishers.keyboardWillBeVisible) { isVisible in
            withAnimation(.easeIn(duration: 0.1)) {
                isKeyboardVisible = isVisible
            }
        }
        .onChange(of: viewModelManager.hasPendingSaveOperations) { hasPendingSaveOperations in
            if !hasPendingSaveOperations {
                dismiss()
                didDismiss?()
            }
        }
    }
    
    func queueSave(_ isLastOne: Bool) {
        if viewModelManager.current.folder == nil {
            showErrorMessage()
            return
        }
        
        viewModelManager.queueSave(idx: selectedPage, viewContext: viewContext)
        
        if !isLastOne {
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
        ImageReview(sources: [Bundle.main.url(forResource: "represent", withExtension: "jpeg")!], entry: nil)
            .preferredColorScheme(.light)
            .environment(\.managedObjectContext, DataController.preview.container.viewContext)
            .previewDevice(PreviewDevice(rawValue: "iPhone 13 Mini"))

        ImageReview(sources: [Bundle.main.url(forResource: "landscape", withExtension: "jpeg")!], entry: nil)
            .preferredColorScheme(.light)
            .environment(\.managedObjectContext, DataController.preview.container.viewContext)
            .previewDevice(PreviewDevice(rawValue: "iPhone 13 Mini"))
    }
}
