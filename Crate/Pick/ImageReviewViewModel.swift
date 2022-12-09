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
    var current: ImageReviewViewModel = .dummy
    @Published var viewModels: [ImageReviewViewModel] = []
    
    func save(viewContext: NSManagedObjectContext) async {
        await withTaskGroup(of: Bool.self) { taskGroup in
            for vm in viewModels {
                taskGroup.addTask {
                    let ok = await vm.save(viewContext: viewContext)
                    return ok
                }
            }
        }
    }
    
    func abortProcessing() {
        viewModels.forEach {
            $0.cancelProcessing()
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
    @Published var name: String = ""
    @Published var description: String = ""
    @Published var folder: Folder?
   
    @Published var _incomingTextBoxes: [BoundingBox] = []
    @Published var textBoundingBoxes: [BoundingBox] = []
    @Published var titleBox: BoundingBox?
    
    @Published var didSelectSegmentedImage = false
    @Published var segmentedImage: SegmentedImage?
    @Published var imageSize: CGSize = .zero
    @Published var colors: [MMCQ.Color]?
    @Published var tappableBounds: CGRect?
    
    @Published var isFinishedProcessing = false
    
    // MARK: -  processors
  
    let paletteQueue = DispatchQueue(label: "com.crate.color_palette", qos: .background)
    let textProcessor = TextProcessor()
    let personSegmenter = PersonSegmenter()
    var textRecognitionStream: AnyCancellable?
    var imageSegmentationStream: AnyCancellable?

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
    
    func loadImage() async {
        guard let data = await dataProvider.data() else {
            return
        }
       
        DispatchQueue.main.async {
            self.originalImage = UIImage(data: data)?.fixOrientation()
        }
    }
    
    func didTapFolder(_ folder: PictureFolder) async {
        self.folder = Folder(coreDataObject: folder)
    }
    
    @MainActor
    func preprocess(newHeight: CGFloat) async {
        Task(priority: .userInitiated) { [weak self] in
            guard let image = self?.originalImage else {
                return
            }
            
            async let boxes = await textProcessor.performRecognition(image: image)
            async let segmented = await personSegmenter.segment(image: image)
            
            let seg = await segmented
            let foundBoxes = await boxes
            
            guard let self = self else { return }
            self._incomingTextBoxes = foundBoxes
            
            let newSize = image.aspectFittedSize(newHeight)
            self.requestForProcessing(imageSize: newSize)
            
            withAnimation {
                self.segmentedImage = seg
                self.isFinishedProcessing = true
            }
        }
    }
    
    @MainActor
    func requestForProcessing(imageSize: CGSize) {
        self.imageSize = imageSize
       
        textRecognitionStream?.cancel()
        textRecognitionStream = $_incomingTextBoxes
            .receive(on: RunLoop.main)
            .map { (rects: [BoundingBox]) -> [BoundingBox] in
                rects.map { box in
                    let bottomToTopTransform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -1)
                    let rect = box.box.applying(bottomToTopTransform)
                    return BoundingBox(id: UUID(), confidence: box.confidence, box: VNImageRectForNormalizedRect(rect, Int(imageSize.width), Int(imageSize.height)), string: box.string)
                }
            }
            .sink { [weak self] (boxes: [BoundingBox]) in
                guard let self = self else { return }
               
                withAnimation {
                    self.textBoundingBoxes = boxes.filter { $0.semiConfident }
                }
            }
      
        imageSegmentationStream?.cancel()
        imageSegmentationStream = $segmentedImage
            .compactMap { $0 }
            .first()
            .receive(on: RunLoop.main)
            .sink { [weak self] image in
                guard let self = self else { return }
                
                Task(priority: .background) {
                    self.tappableBounds = await image.original.imageResized(to: imageSize).cropRect()
                }
                
                self.colors = ColorThief.getPalette(from: image.original, colorCount: 5)
            }
    }
    
    func cancelProcessing() {
        DispatchQueue.main.async {
            self.imageSegmentationStream?.cancel()
            self.textRecognitionStream?.cancel()
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
        
//        entry.original = ImageStorage.shared.write(originalImage, entryID: entry.id!, isOriginal: true)
        entry.modified = (didSelectSegmentedImage) ? await ImageStorage.shared.write(segmentedImage?.original.trimmingTransparentPixels(), entryID: entry.id!, isOriginal: false) : nil
        entry.boxes = NSArray()
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
