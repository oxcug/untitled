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

struct Separator: View {
    var body: some View {
        Rectangle()
            .frame(height: 0.2)
            .foregroundColor(.gray)
    }
}

struct ImageReview: View {
    let images: [ImagePayload]
    @State var progress = 1
    @State var name: String = ""
    @State private var keyboardHeight: CGFloat = 0
    
    @FocusState private var isNameFocused: Bool
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ZStack(alignment: .bottom) {
                    ScrollView(.vertical) {
                        editor(proxy: proxy)
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
                            .padding(.horizontal, 40)
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
                    Text("\(progress) of \(images.count)")
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onReceive(Publishers.keyboardHeight) { height in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        self.keyboardHeight = height
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func editor(proxy: GeometryProxy) -> some View {
        VStack(spacing: 30) {
            ScrollViewReader { scrollReader in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHGrid(rows: [.init(.flexible())]) {
                        ForEach(images, id: \.id) { image in
                            let imageHeight = proxy.size.height * 0.6
                            let textFieldLocation = imageHeight + 55 + 150
                            let screenHeight = UIScreen.main.bounds.height
                            let padding = max(0, textFieldLocation - (screenHeight - keyboardHeight))
                            
                            Image(uiImage: image.modified ?? image.original)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: proxy.size.width, height: imageHeight - padding)
                                .id(image.id)
                        }
                    }
                }
                .onChange(of: progress) { newValue in
                    let idx = progress - 1
                    scrollReader.scrollTo(images[idx].id)
                }
            }
            
            VStack(spacing: 20) {
                GeometryReader { proxy in
                    TextField("Name this...", text: $name)
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
                }
            }
        }
    }
    
    var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHGrid(rows: [.init(.flexible())], spacing: 0) {
                ForEach(Folder.provided) { folder in
                    Button {
                    } label: {
                        HStack(spacing: 0) {
                            if let emoji = folder.emoji {
                                Text(emoji)
                            }
                            
                            Text(folder.name)
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 10).foregroundColor(folder.color).opacity(0.8))
                    }
                    .padding(.leading, 15)
                }
                
                Button {
                } label: {
                    HStack(spacing: 0) {
                        Text("+ Create Category")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10).foregroundColor(.blue).opacity(0.8))
                }
                .padding(.horizontal, 15)
            }
        }
        .frame(height: 50)
    }
}

struct ImageReview_Previews: PreviewProvider {
    static var previews: some View {
        ImageReview(images: [
            ImagePayload(id: UUID(), original: UIImage(named: "porter.jpeg")!, modified: UIImage(named: "porter.jpeg")!),
            ImagePayload(id: UUID(), original: UIImage(named: "porter.jpeg")!, modified: UIImage(named: "represent.jpeg")!)
        ])
    }
}
