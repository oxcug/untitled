//
//  TextProcessor.swift
//  untitled
//
//  Created by Mike Choi on 10/16/22.
//

import UIKit
import Vision

final class TextProcessor: ObservableObject {
    func performRecognition(image: UIImage) async -> [BoundingBox] {
        guard let cgImage = image.fixOrientation().cgImage else {
            return []
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)

        // Create a new request to recognize text.
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest(completionHandler: { request, error in
                let res = self.recognizeTextHandler(request: request, error: error)
                continuation.resume(returning: res)
            })
            
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en-US"]
            request.revision = 2
            
            do {
                // Perform the text-recognition request.
                try requestHandler.perform([request])
            } catch {
                print("Unable to perform the requests: \(error).")
                continuation.resume(returning: [])
            }
        }
    }
    
    func recognizeTextHandler(request: VNRequest, error: Error?) -> [BoundingBox] {
        guard let observations = request.results as? [VNRecognizedTextObservation] else {
            return []
        }
       
        let theBest = observations.compactMap { $0.topCandidates(1).first }

        return theBest.map { cand in
            print(cand.string, cand.confidence)
            // Find the bounding-box observation for the string range.
            let stringRange = cand.string.startIndex..<cand.string.endIndex
            let boxObservation = try? cand.boundingBox(for: stringRange)
            return BoundingBox(id: UUID(), confidence: boxObservation?.confidence, box: boxObservation?.boundingBox ?? .zero, string: cand.string)
        }
    }
}
