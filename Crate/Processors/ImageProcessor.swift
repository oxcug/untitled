//
//  ImageProcessor.swift
//  untitled
//
//  Created by Mike Choi on 10/12/22.
//

import Combine
import Foundation
import UIKit

final class ImageProcessor {
    static let shared = ImageProcessor()
    private let personSegmenter = PersonSegmenter()
    private let textProcesser = TextProcessor()
    
    var current: ImagePayload?
    
    func process(image: UIImage) -> Future<SegmentedImage?, Never> {
        Future<SegmentedImage?, Never> { promise in
            promise(.success(self.personSegmenter.segment(image: image)))
        }
    }
}
