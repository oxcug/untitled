//
//  ImageReviewViewModel.swift
//  Crate
//
//  Created by Mike Choi on 10/16/22.
//

import CoreData
import Combine
import SwiftUI
import Vision

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
    
    func setupEditMode(detail: DetailPayload) {
        guard let viewModel = ImageReviewViewModel(detail: detail) else {
            return
        }
        
        viewModels = [viewModel]
        current = viewModel
    }
    
    func createViewModels(images: [UIImage]) {
        if !viewModels.isEmpty {
            return
        }
        
        viewModels = images.enumerated().map { ImageReviewViewModel(image: $0.element, pageNumber: $0.offset) }
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
    let image: UIImage
    let pageNumber: Int
    
    @Published var name: String = ""
    @Published var folder: Folder?
   
    @Published var textBoundingBoxes: [BoundingBox] = []
    @Published var titleBox: BoundingBox?
    @Published var selectedTextBoundingBoxes: [BoundingBox] = []
    
    @Published var includeSegmentedImage = true
    @Published var segmentedImage: SegmentedImage?
    @Published var imageSize: CGSize = .zero
    @Published var colors: [MMCQ.Color]?
    
    // MARK: -  processors
  
    let paletteQueue = DispatchQueue(label: "com.crate.color_palette", qos: .background)
    let textProcessor = TextProcessor()
    let personSegmenter = PersonSegmenter()
    var cancellable: AnyCancellable?

    // MARK: -
    
    let encoder = JSONEncoder()
    
    static let dummy = ImageReviewViewModel(image: UIImage(), pageNumber: -1)
    
    init(image: UIImage, pageNumber: Int) {
        self.image = image
        self.pageNumber = pageNumber
    }
    
    init?(detail: DetailPayload) {
        guard let entry = detail.detail, let folder = detail.folder else { return nil}
        self.pageNumber = 0
        self.folder = folder
        self.image = ImageStorage.shared.loadImage(named: entry.original) ?? UIImage()
    }
    
    func didTapFolder(_ folder: PictureFolder) {
        self.folder = Folder(coreDataObject: folder)
    }
   
    func requestForProcessing(imageSize: CGSize) {
        self.imageSize = imageSize
        let fixedImage = image.fixOrientation()
        
        cancellable?.cancel()
        textProcessor.reset()
        textProcessor.performRecognition(image: fixedImage)
        cancellable = textProcessor.$boundingRects.map { (rects: [BoundingBox]) -> [BoundingBox] in
            rects.map { box in
                let bottomToTopTransform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -1)
                let rect = box.box.applying(bottomToTopTransform)
                return BoundingBox(id: UUID(), confidence: box.confidence, box: VNImageRectForNormalizedRect(rect, Int(imageSize.width), Int(imageSize.height)), string: box.string)
            }
        }
        .sink { [weak self] (boxes: [BoundingBox]) in
            guard let self = self else { return }
            
            self.textBoundingBoxes = boxes
            let suggestion = boxes.filter { $0.semiConfident }.max(by: { lft, rht in
                lft.area < rht.area
            })
            
            if let suggested = suggestion {
                self.name = suggested.string
                self.titleBox = suggested
            }
        }
        
        segmentedImage = personSegmenter.segment(image: fixedImage)
        
        paletteQueue.async {
            guard let segmented = self.segmentedImage else {
                return
            }
           
            DispatchQueue.main.async {
                self.colors = ColorThief.getPalette(from: segmented.original, colorCount: 5)
            }
        }
    }
    
    func didTapBoundingBox(_ box: BoundingBox) {
        DispatchQueue.main.async {
            // First tap is the title
            if self.titleBox == nil {
                self.titleBox = box
                self.name = box.string
                self.selectedTextBoundingBoxes.removeAll { $0 == box }
                return
            }
            
            if box == self.titleBox {
                self.titleBox = nil
                self.name = ""
                return
            }
            
            if let idx = self.selectedTextBoundingBoxes.firstIndex(of: box) {
                self.selectedTextBoundingBoxes.remove(at: idx)
            } else {
                self.selectedTextBoundingBoxes.append(box)
            }
        }
    }
    
    func save(viewContext: NSManagedObjectContext) async -> Bool {
        guard let folder = folder else {
            return false
        }
       
        let entry = PictureEntry(context: viewContext)
        let entryID = UUID()
        entry.id = entryID
        entry.name = name
        entry.date = Date()
        
        entry.original = ImageStorage.shared.write(image, entryID: entryID, isOriginal: true)
        entry.modified = ImageStorage.shared.write(segmentedImage?.original.cropImageByAlpha(), entryID: entryID, isOriginal: false)
        entry.boxes = NSArray()
        entry.folder = folder.coreDataObject
        entry.colors = (colors ?? []).map { $0.id }

        do {
            try viewContext.save()
            return true
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
//            return false
        }
    }
}
