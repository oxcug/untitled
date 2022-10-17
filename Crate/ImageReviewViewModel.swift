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

final class ImageReviewManager: ObservableObject {
    var current: ImageReviewViewModel = .dummy
    private var viewModels: [String: ImageReviewViewModel] = [:]
    
    @Published var focus: Focus = .person
    @Published var name: String = ""
    @Published var isMagicEnabled = true
    @Published var folders = Set<Folder>()
    
    @Published var segmentedImage: UIImage?
    @Published var textBoundingRects: [CGRect] = []
   
    @Published var imageSize: CGSize = .zero
    let textProcessor = TextProcessor()
    let personSegmenter = PersonSegmenter()
    
    var incomingImageSizeStream: AnyCancellable?
    var cancellable: AnyCancellable?
    
    func setActiveViewModel(_ viewModel: ImageReviewViewModel) {
        focus = viewModel.focus
        name = viewModel.name
        isMagicEnabled = viewModel.isMagicEnabled
        folders = viewModel.folders
        
        current = viewModel
        
        // Remove old calculatations
        textBoundingRects = []
        segmentedImage = nil
        imageSize = .zero
        
        incomingImageSizeStream = $imageSize
            .filter { $0 != .zero }
            .first()
            .sink {
                self.requestForProcessing(imageSize: $0)
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
                return VNImageRectForNormalizedRect(rect, Int(imageSize.width), Int(imageSize.height))
            }
        }
        .assign(to: \.textBoundingRects, on: self)
        
        segmentedImage = personSegmenter.segment(image: fixedImage)
    }
}

final class ImageReviewViewModel: ObservableObject {
    let image: UIImage
    var focus: Focus = .person
    var name: String = ""
    var isMagicEnabled = true
    var folders = Set<Folder>()
    
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
