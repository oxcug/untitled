//
//  ImageProcessor.swift
//  Crate
//
//  Created by Mike Choi on 10/12/22.
//

import Foundation
import UIKit

final class ImageProcessor {
    static let shared = ImageProcessor()
    private let personSegmenter = PersonSegmenter()
    
    func process(image: UIImage) -> UIImage? {
        personSegmenter.segment(image: image)
    }
}
