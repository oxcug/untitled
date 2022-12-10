//
//  ImageReviewViewModel.swift
//  untitled
//
//  Created by Mike Choi on 10/16/22.
//

import CoreData
import Combine
import SwiftUI
import Vision

protocol DataRetrievable {
    func data() async -> Data?
}

extension URL: DataRetrievable {
    func data() async -> Data? {
        try? Data(contentsOf: self)
    }
}

extension PickedAssetPackage.Path: DataRetrievable {
    func data() async -> Data? {
        await withCheckedContinuation { continuation in
            _ = itemProvider.loadDataRepresentation(for: .image) { data, err in
                continuation.resume(returning: data)
            }
        }
    }
}

// MARK: -

struct SegmentedImage {
    let original: UIImage
    let active: UIImage
    let inactive: UIImage
}

final class ImageReviewManager: ObservableObject {
    @Published var viewModels: [ImageReviewViewModel] = []
    @Published var hasPendingSaveOperations = false
    
    var current: ImageReviewViewModel = .dummy
    
    let queue = OperationQueue()
   
    func queueSave(idx: Int, viewContext: NSManagedObjectContext) {
        let vm = viewModels[idx]
        let lastEntry = (idx == viewModels.count - 1)
        
        if lastEntry {
            hasPendingSaveOperations = true
        }
        
        queue.addOperation {
            Task(priority: lastEntry ? .userInitiated : .background) {
                _ = await vm.save(viewContext: viewContext)
                
                Task { @MainActor in
                    if lastEntry {
                        self.hasPendingSaveOperations = false
                    }
                }
            }
        }
    }
    
    func setupEditMode(entry: EntryEntity) {
        guard let viewModel = ImageReviewViewModel(entry: entry) else {
            return
        }
        
        viewModels = [viewModel]
        current = viewModel
    }
    
    func createViewModels(sources: [DataRetrievable]) {
        if !viewModels.isEmpty {
            return
        }
        
        viewModels = sources.enumerated().map { ImageReviewViewModel(dataProvider: $0.element, pageNumber: $0.offset) }
        if let first = viewModels.first {
            current = first
        }
    }
    
    func selectViewModel(idx: Int) {
        if viewModels.count == idx + 1 {
            return
        }
        
        current = viewModels[idx]
    }
}

final class ImageReviewViewModel: ObservableObject, Identifiable {
    let id = UUID()
    let pageNumber: Int
    var existingEntry: PictureEntry?
    
    @Published var originalImage: UIImage?
    @Published var imageSize: CGSize = .zero
    @Published var name: String = ""
    @Published var description: String = ""
    @Published var folder: Folder?
   
    @Published var textBoundingBoxes: [BoundingBox] = []
    @Published var titleBox: BoundingBox?
    
    @Published var didSelectSegmentedImage = false
    @Published var segmentedImage: SegmentedImage?
    @Published var colors: [MMCQ.Color]?
    @Published var tappableBounds: CGRect?
    
    @Published var isFinishedProcessing = false
    
    // MARK: -  processors
  
    let textProcessor = TextProcessor()
    let personSegmenter = PersonSegmenter()

    // MARK: -
    
    let dataProvider: DataRetrievable
    let encoder = JSONEncoder()
    
    static let dummy = ImageReviewViewModel(dataProvider: URL(filePath: ""), pageNumber: -1)
    
    init(dataProvider: DataRetrievable, pageNumber: Int) {
        self.pageNumber = pageNumber
        self.dataProvider = dataProvider
    }
    
    init?(entry: EntryEntity) {
        guard let entry = entry.entry, let folder = entry.folder else { return nil }
        self.pageNumber = 0
        self.folder = Folder(coreDataObject: folder)
        self.dataProvider = ImageStorage.shared.original(for: entry)
        self.description = entry.detailText ?? ""
        self.name = entry.name ?? ""
        
        existingEntry = entry
    }
    
    func loadImage(maxSize: CGSize) async {
        guard let data = await dataProvider.data() else {
            return
        }
       
        DispatchQueue.main.async {
            if let image = UIImage(data: data)?.fixOrientation() {
                let newSize = image.aspectFittedSize(maxSize)
                self.imageSize = newSize
                self.originalImage = image
            }
        }
    }
    
    func didTapFolder(_ folder: PictureFolder) async {
        self.folder = Folder(coreDataObject: folder)
    }
    
    @MainActor
    func preprocess() async {
        Task(priority: .userInitiated) { [weak self] in
            guard let self = self,
                  let image = self.originalImage else {
                return
            }
            
            async let boxes = await textProcessor.performRecognition(image: image)
            async let segmented = await personSegmenter.segment(image: image)
            await self.requestForProcessing(imageSize: self.imageSize, textBoxes: boxes, segmentedImage: segmented)
            
            withAnimation {
                self.isFinishedProcessing = true
            }
        }
    }
    
    @MainActor
    func requestForProcessing(imageSize: CGSize, textBoxes: [BoundingBox], segmentedImage: SegmentedImage?) async {
        textBoundingBoxes = textBoxes.map { box in
            let bottomToTopTransform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -1)
            let rect = box.box.applying(bottomToTopTransform)
            return BoundingBox(id: UUID(), confidence: box.confidence, box: VNImageRectForNormalizedRect(rect, Int(imageSize.width), Int(imageSize.height)), string: box.string)
        }.filter {
            $0.semiConfident
        }
      
        if let segmentedImage = segmentedImage {
            tappableBounds = await segmentedImage.original.imageResized(to: imageSize).cropRect()
            colors = ColorThief.getPalette(from: segmentedImage.original, colorCount: 5)
            
            withAnimation {
                self.segmentedImage = segmentedImage
            }
        }
    }

    func didTapBoundingBox(_ box: BoundingBox) {
        DispatchQueue.main.async {
            if box == self.titleBox {
                self.titleBox = nil
                self.name = ""
            } else {
                self.titleBox = box
                self.name = box.string
            }
        }
    }
    
    func save(viewContext: NSManagedObjectContext) async -> Bool {
        guard let folder = folder else {
            return false
        }
       
        let entry: PictureEntry
        
        if let existingEntry = existingEntry {
            entry = existingEntry
        } else {
            entry = PictureEntry(context: viewContext)
            let entryID = UUID()
            entry.id = entryID
        }
        
        entry.name = name
        entry.date = Date()
        entry.detailText = description
        
        entry.original = ImageStorage.shared.write(originalImage, entryID: entry.id!, isOriginal: true)
        entry.modified = (didSelectSegmentedImage) ? await ImageStorage.shared.write(segmentedImage?.original.trimmingTransparentPixels(), entryID: entry.id!, isOriginal: false) : nil
        entry.folder = folder.coreDataObject
        entry.colors = (colors ?? []).map { $0.id }

        do {
            try viewContext.save()
            return true
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}
