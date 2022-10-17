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

enum Focus: String, CaseIterable {
    case person, text
}

enum ProcessorState {
    case done, processing
}

struct BoundingBox: Identifiable, Hashable {
    let id = UUID()
    let box: CGRect
}

final class ImageReviewManager: ObservableObject {
    var current: ImageReviewViewModel = .dummy
    private var viewModels: [String: ImageReviewViewModel] = [:]
    
    @Published var focus: Focus = .text
    @Published var name: String = ""
    @Published var isMagicEnabled = true
    @Published var folders = Set<Folder>()
    
    @Published var segmentedImage: UIImage?
    @Published var textBoundingBoxes: [BoundingBox] = []
    @Published var selectedTextBoundingBoxes = Set<BoundingBox>()
    
    @Published var imageSize: CGSize = .zero
    @Published var state: ProcessorState = .processing
    
    // MARK: -  processors
    let textProcessor = TextProcessor()
    let personSegmenter = PersonSegmenter()
    
    // MARK: -  streams
    var incomingImageSizeStream: AnyCancellable?
    var cancellable: AnyCancellable?
    
    // MARK: -
    
    func setActiveViewModel(_ viewModel: ImageReviewViewModel) {
        focus = viewModel.focus
        name = viewModel.name
        isMagicEnabled = viewModel.isMagicEnabled
        folders = viewModel.folders
        selectedTextBoundingBoxes = Set(viewModel.selectedTextBoundingRects.map(BoundingBox.init))
        
        current = viewModel
        
        // Remove old calculatations
        textBoundingBoxes = []
        segmentedImage = nil
        imageSize = .zero
        
        state = .processing
        incomingImageSizeStream = $imageSize
            .filter { $0 != .zero }
            .first()
            .sink { [weak self] in
                self?.state = .done
                self?.requestForProcessing(imageSize: $0)
            }
    }
    
    func requestForProcessing(imageSize: CGSize) {
        self.imageSize = imageSize
        let fixedImage = current.image.fixOrientation()
        
        cancellable?.cancel()
        textProcessor.reset()
        textProcessor.performRecognition(image: fixedImage)
        cancellable = textProcessor.$boundingRects.map { rects in
            rects.map { box in
                let bottomToTopTransform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -1)
                let rect = box.applying(bottomToTopTransform)
                return BoundingBox(box: VNImageRectForNormalizedRect(rect, Int(imageSize.width), Int(imageSize.height)))
            }
        }
        .assign(to: \.textBoundingBoxes, on: self)
        
        segmentedImage = personSegmenter.segment(image: fixedImage)
    }

    func didTapBoundingBox(_ box: BoundingBox) {
        DispatchQueue.main.async {
            if self.selectedTextBoundingBoxes.contains(box) {
                self.selectedTextBoundingBoxes.remove(box)
            } else {
                self.selectedTextBoundingBoxes.insert(box)
            }
        }
    }
}

final class ImageReviewViewModel: ObservableObject {
    let image: UIImage
    var focus: Focus = .text
    var name: String = ""
    var isMagicEnabled = true
    var folders = Set<Folder>()
    var selectedTextBoundingRects = Set<CGRect>()
    
    static let dummy = ImageReviewViewModel(image: UIImage())
    
    init(image: UIImage) {
        self.image = image
    }
    
    func didTapFolder(_ folder: Folder) {
        if folders.contains(folder) {
            folders.remove(folder)
        } else {
            folders.insert(folder)
        }
    }
    
    func save() {
        //        folders.forEach {
        //            let modified = payload.modified?.cropImageByAlpha()
        //            let colors = (modified == nil) ? [] : ColorThief.getPalette(from: modified!, colorCount: 4)
        //            let entry = Entry(id: UUID(),
        //                              name: name,
        //                              date: Date(),
        //                              original: payload.original,
        //                              modified: modified,
        //                              colors: colors ?? [])
        //            FolderStorage.shared.add(entry: entry, to: $0)
        //        }
    }
}
