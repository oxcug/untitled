//
//  ShareView.swift
//  untitledShareExtension
//
//  Created by Mike Choi on 11/29/22.
//

import Combine
import SwiftUI

final class ShareViewModel: ObservableObject {
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    var imagesStream: AnyCancellable?
    
    @Published var size: CGFloat?
    
    var allowedOffset: CGFloat? {
        guard let size = size else {
            return nil
        }
        
        return (size - UIScreen.main.bounds.width) / 2
    }
}

struct ShareView: View {
    let imagesStream: CurrentValueSubject<[UIImage], Never>
   
    @State var images: [UIImage] = []
    @State var stackOffset: CGFloat = 0
    @State var underlineLength: CGFloat = 0
    @StateObject var viewModel = ShareViewModel()
    let feedback = UINotificationFeedbackGenerator()
    
    var openApp: (() -> ())?
    
    var body: some View {
        VStack(spacing: 28) {
            LazyHStack(spacing: 4) {
                ForEach(Array(images.enumerated()), id: \.self.offset) { (offset, image) in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 120)
                        .cornerRadius(10)
                        .padding(.leading, offset == 0 ? 15 : 0)
                        .padding(.trailing, offset == images.count - 1 ? 15 : 0)
                }
            }
            .offset(x: -stackOffset)
            .frame(height: 200)
            .readSize { size in
                viewModel.size = size.width
            }
            .padding(.vertical)
           
            VStack(spacing: 15) {
                ZStack(alignment: .bottomLeading) {
                    Text("added to inbox.")
                        .font(.system(size: 18, weight: .semibold, design: .default))
                    
                    Rectangle()
                        .frame(height: 4)
                        .offset(y: 5)
                        .frame(width: underlineLength)
                }
                
                Text("review them later and happy collecting")
                    .font(.system(size: 15, weight: .regular, design: .default))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            
            Button {
                openApp?()
            } label: {
                Text("go to app")
                    .font(.system(size: 15, weight: .semibold, design: .default))
                    .foregroundColor(Color(uiColor: .systemBackground))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundColor(Color(uiColor: .label))
                    )
            }
            .padding()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).delay(0.15)) {
                underlineLength = 130
            }
            
            feedback.notificationOccurred(.success)
        }
        .onReceive(viewModel.timer) { _  in
            guard let allowedOffset = viewModel.allowedOffset,
                  allowedOffset > 0 else {
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
        .task {
            viewModel.imagesStream = imagesStream
                .receive(on: RunLoop.main)
                .assign(to: \.images, on: self)
        }
    }
}

struct ShareView_Previews: PreviewProvider {
    static var previews: some View {
        ShareView(imagesStream: .init([.init(named: "outfit.jpeg")!, .init(named: "IMG_2923.PNG")!, .init(named: "represent.jpeg")!, .init(named: "IMG_2923.PNG")!, .init(named: "IMG_2923.PNG")!, .init(named: "IMG_2923.PNG")!]))
//        ShareView(images: [.init(named: "outfit.jpeg")!, .init(named: "IMG_2923.PNG")!])
    }
}
