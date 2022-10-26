//
//  ImageDetailView.swift
//  Crate
//
//  Created by Mike Choi on 10/13/22.
//

import Combine
import SwiftUI
import UIKit

final class PictureEntryDetailViewModel: ObservableObject {
    lazy var relativeDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .short
        df.doesRelativeDateFormatting = true
        return df
    }()
    
    @Published var payload: DetailPayload = .dummy
    
    @Published var name = "Untitled"
    @Published var dateString = "Untitled"
    @Published var originalImage: UIImage?
    @Published var modifiedImage: UIImage?
    @Published var palette: [UIColor] = []
    
    var payloadParseStream: AnyCancellable?
    
    init() {
        payloadParseStream = $payload.removeDuplicates().receive(on: RunLoop.main)
            .sink { [weak self] payload in
                self?.reload(payload: payload)
            }
    }

    func reload(payload: DetailPayload) {
        guard let entry = payload.detail else {
            return
        }
        
        originalImage = ImageStorage.shared.loadImage(named: entry.original)
        modifiedImage = ImageStorage.shared.loadImage(named: entry.modified)
        
        let colorStrings = entry.colors ?? []
        palette = colorStrings.map { MMCQ.Color(rgbID: $0).makeUIColor() }
        name = entry.name ?? ""
        if name.count == 0 {
            name = "Untitled"
        }
        
        if let date = entry.date {
            dateString = relativeDateFormatter.string(from: date)
        } else {
            dateString = "Unknown date"
        }
    }
}

struct ImageDetailView: View {
    let proxy: FloatingPanelProxy
    @Binding var detailPayload: DetailPayload
    
    @State var backgroundColor: Color? = .black
    @EnvironmentObject var viewModel: PictureEntryDetailViewModel
    
    var body: some View {
        GeometryReader { reader in
            if let entry = detailPayload.detail, let folder = detailPayload.folder {
                detailBody(entry: entry, folder: folder, reader: reader)
            }
        }
        .onChange(of: detailPayload) { payload in
            proxy.fpc?.isRemovalInteractionEnabled = true
            
            if payload.detail != nil {
                proxy.move(to: .full, animated: true)
            } else {
                proxy.move(to: .hidden, animated: true)
            }
        }
    }
    
    @ViewBuilder
    func detailBody(entry: PictureEntry, folder: Folder, reader: GeometryProxy) -> some View {
        VStack(alignment: .center, spacing: 12) {
            ZStack(alignment: .top) {
                HStack {
                    Button {
                        proxy.move(to: .hidden, animated: true)
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                }
                
                Text(folder.fullName)
                    .foregroundColor(.white)
                    .font(.system(size: 15, weight: .semibold, design: .default))
            }
          
            let savedImage = viewModel.modifiedImage ?? viewModel.originalImage
            if let savedImage {
                Image(uiImage: savedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: reader.size.height * 0.6, alignment: .center)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .foregroundColor(.gray.opacity(0.2))
                                        
                    Image(systemName: "questionmark")
                        .font(.system(size: 30, weight: .semibold, design: .default))
                        .foregroundColor(.white)
                }
                .frame(height: reader.size.height * 0.6, alignment: .center)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 12) {
                    Text(viewModel.name)
                        .font(.system(size: 24, weight: .semibold, design: .default))
                        .foregroundColor(.white)
                    
                    Text(viewModel.dateString)
                        .font(.system(size: 18, weight: .semibold, design: .default))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Menu {
                    Button {
                        
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(role: .destructive) {
                        
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(.white)
                        .font(.system(size: 28, weight: .semibold, design: .default))
                }
            }
            
            VStack(alignment: .leading) {
                Text("PALETTE")
                    .foregroundColor(.gray)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                
                    HStack {
                        ForEach(viewModel.palette) { color in
                            RoundedRectangle(cornerRadius: 6)
                                .foregroundColor(Color(uiColor: color))
                                .frame(width: 40, height: 40)
                        }

                        Spacer()
                    }
            }
            .padding(.vertical)
            
            Spacer()
        }
        .padding(.top, 18)
        .padding(.horizontal, 20)
        .background(.black)
        .onAppear {
            viewModel.payload = detailPayload
        }
    }
}

struct ImageDetailView_Previews: PreviewProvider {
    static let detail: PictureEntry = {
        let obj = PictureEntry(context: DataController.shared.container.viewContext)
        return obj
    }()
    
    @State static var detailPayload: DetailPayload = .init(id: UUID(),
                                                           folder: .init(id: UUID(), name: "Favorites", emoji: "⭐", entries: []),
                                                           detail: detail)
    @StateObject static var panelDelegate = DemoFloatingPanelDelegate()
    @StateObject static var detailViewModel = PictureEntryDetailViewModel()
    
    static var previews: some View {
        HomeView(detailPayload: .constant(.dummy), zoomFactor: .constant(4), showSettings: .constant(false))
            .environment(\.managedObjectContext, DataController.preview.container.viewContext)
            .floatingPanel(delegate: panelDelegate) { proxy in
                ImageDetailView(proxy: proxy, detailPayload: $detailPayload)
                    .environmentObject(detailViewModel)
            }
            .floatingPanelSurfaceAppearance(.phone)
            .floatingPanelContentMode(.fitToBounds)
            .floatingPanelContentInsetAdjustmentBehavior(.never)
    }
}
