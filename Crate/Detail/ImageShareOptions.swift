//
//  ImageShareOptions.swift
//  untitled
//
//  Created by Mike Choi on 11/9/22.
//

import SwiftUI

enum ImageDetailVariation: Int, CaseIterable {
    case justPicture, pictureAndPalette, all
}

struct FullDetailImageShareView: View {
    let name: String
    let dateString: String
    let image: UIImage
    let color: UIColor
    let palette: [UIColor]
    
    let variation: ImageDetailVariation
    
    var body: some View {
        GeometryReader { reader in
            VStack {
                if variation == .justPicture {
                    Spacer()
                }

                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: reader.size.height * 0.7, alignment: .center)
               
                Spacer()
                
                if variation == .all {
                    infoStack
                }
                
                if variation == .all || variation == .pictureAndPalette {
                    paletteStack
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(20)
            .background(Color(uiColor: color))
        }
    }
    
    var infoStack: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(name)
                .font(.system(size: 24, weight: .semibold, design: .default))
                .foregroundColor(.white)
            
            Text(dateString)
                .font(.system(size: 18, weight: .semibold, design: .default))
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    var paletteStack: some View {
        VStack(alignment: .leading) {
            Text("PALETTE")
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
            
            HStack {
                ForEach(palette) { col in
                    RoundedRectangle(cornerRadius: 6)
                        .foregroundColor(Color(uiColor: col))
                        .frame(width: 40, height: 40)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(.white.opacity(col == color ? 0.8 : 0), lineWidth: 2)
                        )
                }
                Spacer()
            }
        }
        .padding(.vertical)
    }
}

struct ImageShareOptionView: View {
    let name: String
    let dateString: String
    let image: UIImage
    let color: UIColor
    let palette: [UIColor]
    
    @State var sharePreviews: [UIImage] = []
    
    var body: some View {
        ZStack {
            if sharePreviews.isEmpty {
                ProgressView()
                    .progressViewStyle(.circular)
            }
            
            VStack(spacing: 4) {
                Text("Choose a format to share")
                    .font(.system(size: 15, weight: .semibold, design: .default))
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 10) {
                    ForEach(sharePreviews, id: \.self) { variation in
                        let image = Image(uiImage: variation)
                        
                        ShareLink(item: Image(uiImage: UIImage(data: variation.pngData()!)!),
                                  subject: Text("Check out this outfit on Crate"),
                                  message: Text("Sign up for Crate to curate your wardrobe"),
                                  preview: SharePreview(name, image: image)) {
                            
                            VStack(spacing: 10) {
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .cornerRadius(8)
                                    .shadow(color: .gray.opacity(0.1), radius: 4)
                                
                                Text("Share")
                                    .font(.system(size: 13, weight: .semibold, design: .default))
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 14)
                                    .foregroundColor(.black)
                                    .background(RoundedRectangle(cornerRadius: 8).foregroundColor(.white))
                            }
                        }
                        .tint(.white)
                        .foregroundColor(.black)
                    }
                }
            }
            .opacity(sharePreviews.isEmpty ? 0 : 1)
            .animation(.easeIn(duration: 0.2), value: sharePreviews)
        }
        .padding()
        .task {
            sharePreviews = ImageDetailVariation.allCases.compactMap {
                let renderer = ImageRenderer(content: FullDetailImageShareView(name: name,
                                                                               dateString: dateString,
                                                                               image: image,
                                                                               color: color,
                                                                               palette: palette,
                                                                               variation: $0))
                renderer.proposedSize = ProposedViewSize(UIScreen.main.bounds.size)
                renderer.scale = 5
                guard let data = renderer.uiImage?.pngData() else {
                    return nil
                }
                
                return UIImage(data: data)
            }
        }
    }
}


struct ImageShareOptionView_Previews: PreviewProvider {
    static var previews: some View {
        ImageShareOptionView(name: "Foobar",
                             dateString: "Today",
                             image: .init(named: "modified_4.png")!,
                             color: .systemBlue,
                             palette: [.black, .white, .systemBrown, .systemBlue])
        .background(.black)
    }
}

