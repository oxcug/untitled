//
//  ImageDetailView.swift
//  Crate
//
//  Created by Mike Choi on 10/13/22.
//

import Combine
import SwiftUI
import Introspect
import UIKit

final class PictureEntryDetailViewModel: ObservableObject {
    lazy var relativeDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .short
        df.doesRelativeDateFormatting = true
        return df
    }()
    
    var payload: DetailPayload = .dummy {
        didSet {
            reload(payload: payload)
        }
    }
    
    @Published var entries: [PictureEntry] = []
    @Published var images: [UUID: UIImage] = [:]
    
    @Published var name = "Untitled"
    @Published var folderName = "Untitled"
    @Published var dateString = "Untitled"
    @Published var palette: [UIColor] = []
    @Published var paletteCache: [UUID: [UIColor]] = [:]
    
    @Published var backgroundColor: UIColor = .black
    
    func reset() {
        backgroundColor = .black
        entries = []
    }
    
    func reload(payload: DetailPayload) {
        guard let entry = payload.detail,
              let folder = payload.folder,
              let currentIndexInFolder = folder.entries.firstIndex(of: entry) else {
            return
        }
       
        folderName = folder.fullName
        
        let existingEntries = folder.entries
        entries = existingEntries.dropFirst(Int(currentIndexInFolder)) + existingEntries.dropLast(existingEntries.count - Int(currentIndexInFolder))
        images = Dictionary(uniqueKeysWithValues: entries.map {
            ($0.id ?? UUID(), ImageStorage.shared.loadImage(named: $0.modified) ?? UIImage())
        })
        
        if let first = entries.first {
            reload(entry: first)
        }
    }
   
    func reload(entry: PictureEntry)  {
        palette = loadPalette(entry: entry)
        backgroundColor = palette.first ?? .black
        
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
    
    func loadPalette(entry: PictureEntry) -> [UIColor] {
        if let cachedPalette = paletteCache[entry.id ?? UUID()] {
            return cachedPalette
        } else {
            let colorStrings = entry.colors ?? []
            let palette = colorStrings.map { MMCQ.Color(rgbID: $0).makeUIColor() }
            paletteCache[entry.id ?? UUID()] = palette
            return palette
        }
    }
}

struct ImageDetailView: View {
    let detailPayload: DetailPayload
    let selectionFeedbackGenerator = UIImpactFeedbackGenerator(style: .rigid)
    
    @State var cur: PictureEntry = .init()
    @EnvironmentObject var viewModel: PictureEntryDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        GeometryReader { reader in
            VStack(alignment: .center, spacing: 12) {
                modalHeader
                    .padding(.horizontal, 20)
                
                mainImage(reader: reader)
                
                infoHeader
                    .padding(.horizontal, 20)

                paletteSection
                    .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.top, 18)
            .background(Color(uiColor: viewModel.backgroundColor))
        }
        .task {
            viewModel.payload = detailPayload
        }
        .onChange(of: cur) { cur in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.27) {
                withAnimation {
                    viewModel.reload(entry: cur)
                }
            }
        }
        .onDisappear {
            viewModel.reset()
        }
    }
    
    var modalHeader: some View {
        ZStack(alignment: .top) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
            
            Text(viewModel.folderName)
                .foregroundColor(.white)
                .font(.system(size: 15, weight: .semibold, design: .default))
        }
    }
    
    @ViewBuilder
    func mainImage(reader: GeometryProxy) -> some View {
        TabView(selection: $cur) {
            ForEach(viewModel.entries, id: \.self) { entry in
                Image(uiImage: viewModel.images[entry.id ?? UUID()] ?? UIImage())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: reader.size.height * 0.6, alignment: .center)
                    .task {
                        _ = viewModel.loadPalette(entry: entry)
                    }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }
    
    var infoHeader: some View {
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
        
    }
    
    var paletteSection: some View {
        VStack(alignment: .leading) {
            Text("PALETTE")
                .foregroundColor(.gray)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
            
                HStack {
                    ForEach(viewModel.palette) { color in
                        Button {
                            selectionFeedbackGenerator.impactOccurred()
                            
                            withAnimation(.easeInOut) {
                                viewModel.backgroundColor = color
                            }
                        } label: {
                            let isSelected = (viewModel.backgroundColor == color)
                            RoundedRectangle(cornerRadius: 6)
                                .foregroundColor(Color(uiColor: color))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(.white.opacity(isSelected ? 1 : 0), lineWidth: 2)
                                )
                        }
                    }

                    Spacer()
                }
        }
        .padding(.vertical)
    }
}

extension View {
    public func introspectTabScrollView(customize: @escaping (UIScrollView) -> ()) -> some View {
        return inject(UIKitIntrospectionView(
            selector: { introspectionView in
                guard let viewHost = Introspect.findViewHost(from: introspectionView) else {
                    return nil
                }
                return Introspect.previousSibling(containing: UIScrollView.self, from: viewHost)
            },
            customize: customize
        ))
    }
}

struct ImageDetailView_Previews: PreviewProvider {
    static let detail: PictureEntry = {
        let obj = PictureEntry(context: DataController.shared.container.viewContext)
        return obj
    }()
    
    @StateObject static var panelDelegate = DemoFloatingPanelDelegate()
    @StateObject static var detailViewModel = PictureEntryDetailViewModel()
    
    static var previews: some View {
        HomeView(detailPayload: .dummy, zoomFactor: .constant(4), showSettings: .constant(false), showLabels: .constant(false))
            .environment(\.managedObjectContext, DataController.preview.container.viewContext)
            .floatingPanelSurfaceAppearance(.phone)
            .floatingPanelContentMode(.fitToBounds)
            .floatingPanelContentInsetAdjustmentBehavior(.never)
    }
}
