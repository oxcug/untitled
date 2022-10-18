//
//  ImageReviewViewModel.swift
//  Crate
//
//  Created by Mike Choi on 10/16/22.
//

import Combine
import SwiftUI
import UIKit
import Vision

struct BoundingBox: Identifiable, Hashable, Codable {
    let id: UUID
    let box: CGRect
    let string: String
}

final class ImageReviewManager: ObservableObject {
    var current: ImageReviewViewModel = .dummy
    @Published var viewModels: [ImageReviewViewModel] = []
    
    func save() {
        viewModels.forEach {
            $0.save()
        }
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

struct SegmentedImage {
    let original: UIImage
    let active: UIImage
    let inactive: UIImage
}

final class ImageReviewViewModel: ObservableObject, Identifiable {
    let id = UUID()
    
    let image: UIImage
    let pageNumber: Int
    
    @Published var name: String = ""
    @Published var folder: Folder?
    
    @Published var textBoundingBoxes: [BoundingBox] = []
    @Published var selectedTextBoundingBoxes: [BoundingBox] = []
    
    @Published var includeSegmentedImage = true
    @Published var segmentedImage: SegmentedImage?
    @Published var imageSize: CGSize = .zero
    
    // MARK: -  processors
    
    let textProcessor = TextProcessor()
    let personSegmenter = PersonSegmenter()

    // MARK: -  streams
    
    var incomingImageSizeStream: AnyCancellable?
    var cancellable: AnyCancellable?

    // MARK: -
    
    static let dummy = ImageReviewViewModel(image: UIImage(), pageNumber: -1)
    
    init(image: UIImage, pageNumber: Int) {
        self.image = image
        self.pageNumber = pageNumber
    }
    
    func didTapFolder(_ folder: Folder) {
        self.folder = folder
    }
    
    func requestForProcessing(imageSize: CGSize) {
        self.imageSize = imageSize
        let fixedImage = image.fixOrientation()
        
        cancellable?.cancel()
        textProcessor.reset()
        textProcessor.performRecognition(image: fixedImage)
        cancellable = textProcessor.$boundingRects.map { rects in
            rects.map { box in
                let bottomToTopTransform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -1)
                let rect = box.box.applying(bottomToTopTransform)
                return BoundingBox(id: UUID(), box: VNImageRectForNormalizedRect(rect, Int(imageSize.width), Int(imageSize.height)), string: box.string)
            }
        }
        .assign(to: \.textBoundingBoxes, on: self)
        
        segmentedImage = personSegmenter.segment(image: fixedImage)
    }
    
    func didTapBoundingBox(_ box: BoundingBox) {
        DispatchQueue.main.async {
            if let idx = self.selectedTextBoundingBoxes.firstIndex(of: box) {
                self.selectedTextBoundingBoxes.remove(at: idx)
            } else {
                self.selectedTextBoundingBoxes.append(box)
            }
        }
    }
    
    func save() {
        guard let folder = folder else {
            return
        }
        
        let colors = (segmentedImage == nil) ? [] : ColorThief.getPalette(from: segmentedImage!.original, colorCount: 4)
        let entry = Entry(id: id,
                          name: name,
                          textBoundingBoxes: selectedTextBoundingBoxes,
                          date: Date(),
                          original: image,
                          modified: segmentedImage?.original.cropImageByAlpha(),
                          colors: colors ?? [])
        
        FolderStorage.shared.add(entry: entry, to: folder)
    }
}
