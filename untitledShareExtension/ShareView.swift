//
//  ShareView.swift
//  untitledShareExtension
//
//  Created by Mike Choi on 11/29/22.
//

import Foundation
import SwiftUI

final class ShareViewModel: ObservableObject {
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    @Published var size: CGFloat?
    
    var allowedOffset: CGFloat? {
        guard let size = size else {
            return nil
        }
        
        return (size - UIScreen.main.bounds.width) / 2
    }
}

struct ShareView: View {
    let images: [UIImage]
    
    @State var infoOpacity: CGFloat = 0
    @State var stackOffset: CGFloat = 0
    @StateObject var viewModel = ShareViewModel()
    
    var openApp: (() -> ())?
    
    var body: some View {
        VStack(spacing: 32) {
            LazyHStack(spacing: 4) {
                ForEach(Array(images.enumerated()), id: \.self.offset) { (offset, image) in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 150)
                        .cornerRadius(10)
                        .padding(.leading, offset == 0 ? 15 : 0)
                        .padding(.trailing, offset == images.count - 1 ? 15 : 0)
                }
            }
            .offset(x: -stackOffset)
            .frame(height: 150)
            .readSize { size in
                viewModel.size = size.width
            }

            VStack(spacing: 18) {
                Image(systemName: "tray.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 24, weight: .semibold, design: .default))
                    .padding()
                    .background(Circle()
                        .foregroundColor(.green)
                        .frame(width: 50, height: 50))
                
                VStack(spacing: 8) {
                    Text("Added to Inbox")
                        .font(.system(size: 18, weight: .semibold, design: .default))
                    
                    Text("Review them later and happy collecting")
                        .font(.system(size: 15, weight: .regular, design: .default))
                }
            }
            .opacity(infoOpacity)
            
            Button {
                openApp?()
            } label: {
                Text("Go to app")
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.25)) {
                infoOpacity = 1
            }
        }
        .onReceive(viewModel.timer) { _  in
            guard let allowedOffset = viewModel.allowedOffset else {
                return
            }
            
            if stackOffset >= allowedOffset {
                viewModel.timer.upstream.connect().cancel()
                return
            }
            
            withAnimation {
                stackOffset += 0.7
            }
        }
    }
}

struct ShareView_Previews: PreviewProvider {
    static var previews: some View {
        ShareView(images: [.init(named: "outfit.jpeg")!, .init(named: "IMG_2923.PNG")!, .init(named: "represent.jpeg")!, .init(named: "IMG_2923.PNG")!, .init(named: "IMG_2923.PNG")!, .init(named: "IMG_2923.PNG")!])
//        ShareView(images: [.init(named: "outfit.jpeg")!, .init(named: "IMG_2923.PNG")!])
    }
}
