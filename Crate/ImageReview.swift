//
//  ImageReview.swift
//  Crate
//
//  Created by Mike Choi on 10/12/22.
//

import Combine
import SwiftUI

struct Folder: Identifiable, Hashable {
    let id: String
    let emoji: String?
    let name: String
    let color: Color
    
    static let provided = [
        Folder(id: "a", emoji: "🍁", name: "Fall Outfits", color: .orange),
        Folder(id: "b", emoji: "❄️", name: "Winter Outfits", color: .blue),
        Folder(id: "c", emoji: "☕", name: "Cafes", color: .brown),
        Folder(id: "d", emoji: "🎵", name: "Music", color: .black),
        Folder(id: "e", emoji: "🔗", name: "Links", color: .blue),
    ]
}

final class ImageReviewViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var isMagicEnabled = true
    @Published var folders = Set<Folder>()
    
    let payload: ImagePayload
    
    init(payload: ImagePayload) {
        self.payload = payload
    }
    
    func didTapFolder(_ folder: Folder) {
        if folders.contains(folder) {
            folders.remove(folder)
        } else {
            folders.insert(folder)
        }
    }
}

struct Separator: View {
    var body: some View {
        Rectangle()
            .frame(height: 0.2)
            .foregroundColor(.gray)
    }
}

struct ImageReview: View {
    let viewModels: [ImageReviewViewModel]
    @StateObject var current: ImageReviewViewModel
    @State var progress = 1
    @State private var keyboardHeight: CGFloat = 0
    
    @FocusState private var isNameFocused: Bool
    @Environment(\.presentationMode) var presentationMode

    let toggleFeedback = UIImpactFeedbackGenerator(style: .rigid)
    let selectionFeedback = UISelectionFeedbackGenerator()
    
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
                    
                    VStack(spacing: 0) {
                        Separator()
                        
                        ZStack {
                            Button {
                                progress += 1
                            } label: {
                                Text("that's fire")
                                    .font(.system(size: 18, weight: .semibold, design: .default))
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(RoundedRectangle(cornerRadius: 10).foregroundColor(.black))
                            }
                            .padding()
                            .padding(20)
                            .background(Rectangle().foregroundColor(Color(uiColor: .systemBackground)))
                        }
                    }
                }
            }
            .edgesIgnoringSafeArea(.bottom)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("\(progress) of \(viewModels.count)")
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onReceive(Publishers.keyboardHeight) { height in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        self.keyboardHeight = height
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func editor(size: CGSize) -> some View {
        VStack(spacing: 30) {
            ZStack(alignment: .bottomTrailing) {
                ScrollViewReader { scrollReader in
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHGrid(rows: [.init(.flexible())]) {
                            ForEach(viewModels, id: \.payload.id) { image in
                                let imageHeight = size.height * 0.6
                                let textFieldLocation = imageHeight + 55 + 150
                                let screenHeight = UIScreen.main.bounds.height
                                let padding = max(0, textFieldLocation - (screenHeight - keyboardHeight))
                                
                                ZStack {
                                    Image(uiImage: image.payload.original)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .cornerRadius(10)
                                        .frame(width: size.width, height: imageHeight - padding)
                                        .opacity(current.isMagicEnabled ? 0 : 1)
                                    
                                    Image(uiImage: image.payload.modified ?? image.payload.original)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .cornerRadius(10)
                                        .frame(width: size.width, height: imageHeight - padding)
                                }
                                .id(image.payload.id)
                            }
                        }
                    }
                    .onChange(of: progress) { newValue in
                        let idx = progress - 1
                        if idx == viewModels.count {
                            presentationMode.wrappedValue.dismiss()
                        } else {
                            scrollReader.scrollTo(viewModels[idx].payload.id)
                        }
                    }
                }
                
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        current.isMagicEnabled.toggle()
                    }
                    toggleFeedback.impactOccurred()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "wand.and.rays")
                            .resizable()
                            .frame(width: 18, height: 18)
                            .foregroundColor(.white)
                        
                        Text(current.isMagicEnabled ? "X-Ray on" : "X-Ray off")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8)
                        .foregroundColor(current.isMagicEnabled ? .red : .black)
                        .opacity(0.4))
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
                .padding(.bottom)
            }
          
            VStack(spacing: 20) {
                GeometryReader { proxy in
                    TextField("Name this...", text: $current.name)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal)
                        .focused($isNameFocused)
                }
                
                Separator()
                
                VStack(alignment: .leading) {
                    Text("CATEGORY")
                        .padding(.horizontal)
                        .foregroundColor(.gray)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                    
                    categoryPicker
                    
                    Rectangle()
                        .frame(height: 150)
                        .foregroundColor(Color(uiColor: .systemBackground))
                }
            }
        }
    }
    
    var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHGrid(rows: [.init(.flexible())], spacing: 0) {
                ForEach(Folder.provided) { folder in
                    Button {
                        current.didTapFolder(folder)
                        selectionFeedback.selectionChanged()
                    } label: {
                        let isSelected = (current.folders.contains(folder))
                        
                        HStack(spacing: 4) {
                            ZStack(alignment: .center) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 18))
                                    .opacity(isSelected ? 1 : 0)
                                
                                if let emoji = folder.emoji {
                                    Text(emoji)
                                        .font(.system(size: 18))
                                        .opacity(isSelected ? 0 : 1)
                                }
                            }
                            
                            Text(folder.name)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 10).foregroundColor(folder.color).opacity(isSelected ? 0.4 : 0.7))
                    }
                    .padding(.leading, 15)
                }
                
                Button {
                } label: {
                    HStack(spacing: 0) {
                        Text("+ New Category")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10).foregroundColor(.blue).opacity(0.4))
                }
                .padding(.horizontal, 15)
            }
        }
        .frame(height: 50)
    }
}

struct ImageReview_Previews: PreviewProvider {
    static var previews: some View {
        ImageReview(viewModels: [
            ImagePayload(id: UUID(), original: UIImage(named: "porter.jpeg")!, modified: UIImage(named: "porter.jpeg")!),
            ImagePayload(id: UUID(), original: UIImage(named: "porter.jpeg")!, modified: UIImage(named: "represent.jpeg")!)
        ].map { ImageReviewViewModel(payload: $0) },
                    current: ImageReviewViewModel(payload: ImagePayload(id: UUID(), original: UIImage(named: "porter.jpeg")!, modified: UIImage(named: "porter.jpeg")!)))
    }
}
