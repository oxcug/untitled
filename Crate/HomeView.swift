//
//  ContentView.swift
//  Crate
//
//  Created by Mike Choi on 10/12/22.
//

import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)], animation: .default)
    private var items: FetchedResults<Item>
    
    @State private var showingImagePicker = false
    @State private var showImageReviewModal = false
    @State private var imagesPayload: ImagesPayload?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                List {
                    section(with: "📍 Places")
                    section(with: "🎵 Music")
                    section(with: "🔗 Links")
                    section(with: "👕 Outfits")
                }
                .listStyle(.plain)
                
                Button {
                    showingImagePicker = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 28, weight: .semibold, design: .default))
                        .foregroundColor(Color.white)
                        .padding()
                        .background(Circle().foregroundColor(.blue))
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Crate")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(imagesPayload: $imagesPayload)
        }
        .fullScreenCover(item: $imagesPayload) { payload in
            let models = payload.images.map(ImageReviewViewModel.init)
            ImageReview(viewModels: models, current: models.first!)
        }
    }
    
    @ViewBuilder
    func section(with name: String) -> some View {
        Text(name)
            .font(.system(size: 16, weight: .medium, design: .monospaced))
        
        LazyHGrid(rows: [GridItem(.flexible())]) {
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .foregroundColor(Color(uiColor: .systemBackground))
                    .shadow(radius: 0.6)
                
                VStack(alignment: .leading, spacing: 15) {
                    Image(systemName: "photo.artframe")
                        .resizable()
                        .frame(height: 100)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Dishoom")
                            .font(.system(size: 18, weight: .semibold, design: .default))
                        
                        Text("2 weeks ago")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .frame(width: 180, height: 160, alignment: .leading)
            .padding(.vertical)
        }
        .listRowSeparator(.hidden)
        .padding(.bottom)
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
