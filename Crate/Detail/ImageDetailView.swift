//
//  ImageDetailView.swift
//  untitled
//
//  Created by Mike Choi on 10/13/22.
//

import Combine
import SwiftUI
import UIKit

struct ImageDetailView: View {
    let detailPayload: DetailPayload
    let selectionFeedbackGenerator = UIImpactFeedbackGenerator(style: .rigid)
    
    @State var isZooming = false
    @State var offset: CGPoint = .zero
    @State var scale: CGFloat = .zero
    @State var scalePoisition: CGPoint = .zero
    @State var showEditModal = false
    @State var showShareModal = false
    @State var showDescriptionModal = false
    
    @EnvironmentObject var viewModel: PictureEntryDetailViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var viewContext
    @AppStorage("theme") var theme: Theme = .lightsOff
    
    let heightRatio = 0.58
    
    var body: some View {
        GeometryReader { reader in
            VStack(alignment: .center, spacing: 12) {
                modalHeader
                    .padding(.horizontal, 20)
                    .opacity(isZooming ? 0.3 : 1)
                    .animation(.easeInOut, value: isZooming)
                
                mainImage(reader: reader)
                
                infoHeader
                    .padding(.horizontal, 20)
                    .opacity(isZooming ? 0.3 : 1)
                    .animation(.easeInOut(duration: 0.2), value: isZooming)
                
                paletteSection
                    .padding(.horizontal, 20)
                    .opacity(isZooming ? 0.3 : 1)
                    .animation(.easeInOut(duration: 0.2), value: isZooming)
                
                if let description = viewModel.description {
                    MoreText(text: description, backgroundColor: $viewModel.backgroundColor) {
                        showDescriptionModal = true
                    }
                }
                
                Spacer()
            }
            .padding(.top, 18)
            .background(Color(uiColor: viewModel.backgroundColor))
        }
        .task {
            viewModel.payload = detailPayload
        }
        .onChange(of: viewModel.cur) { cur in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.23) {
                withAnimation {
                    viewModel.reload(entry: cur)
                }
            }
        }
        .onDisappear {
            viewModel.reset()
        }
        .fullScreenCover(isPresented: $showEditModal) {
            NavigationStack {
                ImageReview(sources: [], entry: viewModel.cur) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            viewModel.reload(entry: viewModel.cur)
                        }
                    }
                }
            }
            .preferredColorScheme(theme.colorScheme)
        }
        .sheet(isPresented: $showDescriptionModal) {
            NavigationStack {
                MoreTextModalView(title: viewModel.name, text: viewModel.description ?? "")
            }
        }
        .presentModal(isPresented: $showShareModal, height: UIScreen.main.bounds.height * 0.45) {
            if let image = viewModel.images[viewModel.cur.id] {
                ImageShareOptionView(name: viewModel.name,
                                     dateString: viewModel.dateString,
                                     image: image,
                                     color: viewModel.backgroundColor,
                                     palette: viewModel.palette)
            }
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
        ZStack(alignment: .center) {
            Image(uiImage: viewModel.images[viewModel.cur.id] ?? UIImage())
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: reader.size.height * heightRatio, alignment: .center)
                .opacity(isZooming ? 1 : 0)
                .offset(x: offset.x, y: offset.y)
                .scaleEffect(1 + (scale < 0 ? 0 : scale), anchor: .init(x: scalePoisition.x, y: scalePoisition.y))
                .disabled(true)
            
            TabView(selection: $viewModel.cur) {
                ForEach(viewModel.entries, id: \.self) { entry in
                    Image(uiImage: viewModel.images[entry.id] ?? UIImage())
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .addPinchToZoom(isZooming: $isZooming, offset: $offset, scale: $scale, scalePosition: $scalePoisition)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: reader.size.height * heightRatio, alignment: .center)
            .opacity(isZooming ? 0 : 1)
        }
        .zIndex(isZooming ? 1000 : 0)
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
                Button(role: .destructive) {
                    if let entry = viewModel.cur.entry {
                        viewContext.delete(entry)
                        try? viewContext.save()
                    }
                    viewModel.deleteCurrent()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                
                Button {
                    showShareModal.toggle()
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                
                Button {
                    showEditModal = true
                } label: {
                    Label("Edit", systemImage: "pencil")
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
                .foregroundColor(.white)
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

struct ImageDetailView_Previews: PreviewProvider {
    static let detail: PictureEntry = {
        let obj = PictureEntry(context: DataController.shared.container.viewContext)
        return obj
    }()
    
    @StateObject static var detailViewModel = PictureEntryDetailViewModel()
    
    static var previews: some View {
        ImageDetailView(detailPayload: .dummy)
            .environment(\.managedObjectContext, DataController.preview.container.viewContext)
            .onAppear {
                detailViewModel.reload(payload: .dummy)
            }
    }
}
