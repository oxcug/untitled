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
        let recognizedStrings = observations.compactMap { observation in
            // Return the string of the top VNRecognizedText instance.
            return observation.topCandidates(1).first?.string
        }
        
        boundingRects = observations.compactMap { observation in
            // Find the top observation.
            guard let candidate = observation.topCandidates(1).first else { return .zero }
            
            // Find the bounding-box observation for the string range.
            let stringRange = candidate.string.startIndex..<candidate.string.endIndex
            let boxObservation = try? candidate.boundingBox(for: stringRange)
            
            // Get the normalized CGRect value.
            return boxObservation?.boundingBox ?? .zero
        }
       
        print(recognizedStrings)
        // Process the recognized strings.
//        processResults(recognizedStrings)
    }
}
