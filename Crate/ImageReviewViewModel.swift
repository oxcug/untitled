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

enum Focus {
    case person, text
}

final class ImageReviewManager: ObservableObject {
    private var current: ImageReviewViewModel = .dummy
    private var viewModels: [String: ImageReviewViewModel] = [:]
    
    @Published var focus: Focus = .text
    @Published var name: String = ""
    @Published var isMagicEnabled = true
    @Published var folders = [Folder]()
    
    let textProcessor = TextProcessor()
    @Published var textBoundingRects: [CGRect] = []
    
    var cancellable: AnyCancellable?
    
    func setActiveViewModel(_ viewModel: ImageReviewViewModel) {
        focus = viewModel.focus
        name = viewModel.name
        isMagicEnabled = viewModel.isMagicEnabled
        folders = Array(viewModel.folders)
        
        current = viewModel
    }
    
    func requestForProcessing(imageSize: CGSize) {
        if focus == .text {
            textProcessor.performRecognition(image: current.image)
            cancellable = textProcessor.$boundingRects.map { rects in
                rects.map { box in
                    let bottomToTopTransform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -1)
                    let rect = box.applying(bottomToTopTransform)
                    return VNImageRectForNormalizedRect(rect, Int(imageSize.width), Int(imageSize.height))
                }
            }
            .assign(to: \.textBoundingRects, on: self)
        } else {
            current.focus = .person
        }
    }
   
    func toggleFocus() {
        cancellable?.cancel()
        
        if focus == .person {
            current.focus = .text
            textProcessor.performRecognition(image: current.image.imageResized(to: CGSize(width: 375, height: 360)))
            cancellable = textProcessor.$boundingRects.assign(to: \.textBoundingRects, on: self)
        } else {
            current.focus = .person
        }
        
        focus = current.focus
    }
}

final class ImageReviewViewModel: ObservableObject {
    let image: UIImage
    var focus: Focus = .text
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
