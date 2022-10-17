//
//  TextProcessor.swift
//  Crate
//
//  Created by Mike Choi on 10/16/22.
//

import UIKit
import Vision

final class TextProcessor: ObservableObject {
    @Published var boundingRects: [CGRect] = []
    var imageSize: CGSize = .zero
    
    func reset() {
        imageSize = .zero
        boundingRects = []
    }
    
    func performRecognition(image: UIImage) {
        guard let cgImage = image.cgImage else {
            return
        }
        
        imageSize = image.size

        let requestHandler = VNImageRequestHandler(cgImage: cgImage)

        // Create a new request to recognize text.
        let request = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US"]
        request.revision = 2

        do {
            // Perform the text-recognition request.
            try requestHandler.perform([request])
        } catch {
            print("Unable to perform the requests: \(error).")
        }
    }
    
    func recognizeTextHandler(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNRecognizedTextObservation] else {
            return
        }
       
        let theBest = observations.compactMap { $0.topCandidates(1).first }

        boundingRects = theBest.map { cand in
            print(cand.string, cand.confidence)
            // Find the bounding-box observation for the string range.
            let stringRange = cand.string.startIndex..<cand.string.endIndex
            let boxObservation = try? cand.boundingBox(for: stringRange)
            
            // Get the normalized CGRect value.
            return boxObservation?.boundingBox ?? .zero
        }
    }
}
