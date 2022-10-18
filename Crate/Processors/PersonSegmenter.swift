//
//  PersonSegmenter.swift
//  Crate
//
//  Created by Mike Choi on 10/12/22.
//

import UIKit
import Combine
import Vision
import CoreImage.CIFilterBuiltins

final class PersonSegmenter {
    let context = CIContext()
    let request = VNGeneratePersonSegmentationRequest()
    
    func segment(image: UIImage) -> SegmentedImage? {
        guard let foregroundImage = image.fixOrientation().cgImage else {
            print("Missing required images")
            return nil
        }
        
        // Create request
        request.qualityLevel = .balanced
        request.revision = VNGeneratePersonSegmentationRequestRevision1
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8
        
        // Create request handler
        let requestHandler = VNImageRequestHandler(
            cgImage: foregroundImage,
            options: [:])
        
        do {
            try requestHandler.perform([request])
            guard let mask = request.results?.first else {
                print("Error generating person segmentation mask")
                return nil
            }
            
            let foreground = CIImage(cgImage: foregroundImage)
            let maskImage = CIImage(cvPixelBuffer: mask.pixelBuffer)
            
            guard let output = blendImages(foreground: foreground, mask: maskImage) else {
                print("Error blending images")
                return nil
            }
            
            // Update photoOutput
            if let res = renderAsUIImage(output) {
                return SegmentedImage(original: res,
                                      active: outlineBorder(image: output, color: CIImage(color: CIColor(color: .systemBlue))) ?? UIImage(),
                                      inactive: outlineBorder(image: output, color: CIImage(color: CIColor(color: .systemGray.withAlphaComponent(0.5)))) ?? UIImage())
            }
        } catch {
            print("Error processing person segmentation request")
            return nil
        }
        
        return nil
    }
    
    private func blendImages(foreground: CIImage, mask: CIImage, isRedMask: Bool = false) -> CIImage? {
        // scale mask
        let maskScaleX = foreground.extent.width / mask.extent.width
        let maskScaleY = foreground.extent.height / mask.extent.height
        let maskScaled = mask.transformed(by: __CGAffineTransformMake(maskScaleX, 0, 0, maskScaleY, 0, 0))
        
        let blendFilter = isRedMask ? CIFilter.blendWithRedMask() : CIFilter.blendWithMask()
        blendFilter.inputImage = foreground
        blendFilter.maskImage = maskScaled
        return blendFilter.outputImage
    }
    
    private func outlineBorder(image: CIImage, color: CIImage) -> UIImage? {
        // Apply morphology maximum to "erode" image in all direction into transparent area.
        let filter = CIFilter.morphologyMaximum()
        filter.inputImage = image
        filter.radius = Float(max(image.extent.size.width, image.extent.size.height) * 0.005)
        
        let eroded = filter.outputImage!
        
        // Turn all pixels of eroded image into desired border color.
        let colorized = CIBlendKernel.sourceAtop.apply(foreground: color, background: eroded)!.cropped(to: eroded.extent)
        
        // Blend original image over eroded, colorized image.
        return renderAsUIImage(image.composited(over: colorized))
    }
    
    private func renderAsUIImage(_ image: CIImage) -> UIImage? {
        guard let cgImage = context.createCGImage(image, from: image.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
    
    // TODO: Process video in the future
    private func processVideoFrame(foreground: CVPixelBuffer, background: CGImage) -> CIImage? {
        // Create request handler
        let ciForeground = CIImage(cvPixelBuffer: foreground)
        let personSegmentFilter = CIFilter.personSegmentation()
        personSegmentFilter.inputImage = ciForeground
        if let mask = personSegmentFilter.outputImage {
            guard let output = blendImages(
                foreground: ciForeground,
                mask: mask,
                isRedMask: true) else {
                print("Error blending images")
                return nil
            }
            return output
        }
        return nil
    }
}
