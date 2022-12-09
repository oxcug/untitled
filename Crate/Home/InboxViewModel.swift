//
//  InboxViewModel.swift
//  untitledShareExtension
//
//  Created by Mike Choi on 12/3/22.
//

import UIKit
import SwiftUI
import QuickLook

struct InboxImage: Identifiable, Hashable {
    let id = UUID()
    let image: UIImage
    let filePath: URL
}

final class InboxViewModel: ObservableObject {
    @Published var imageURLs: [URL] = []
    
    let imageLoadQueue = DispatchQueue(label: "com.mjc.crate.image.load")
    let allowedPathExtensions: Set<String> = ["jpg", "jpeg", "png"]
    
    func loadInboxThumbnails() {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.mjc.untitled") else {
            imageURLs = []
            return
        }
       
        let contents = (try? fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)) ?? []
        imageURLs = contents.filter { allowedPathExtensions.contains($0.pathExtension) }
    }
    
    func clearInbox() {
        imageURLs.forEach { url in
            try? FileManager.default.removeItem(at: url)
        }
        
        imageURLs = []
    }
}

extension InboxViewModel {
    func resize(url: URL, maxPixelSize: Int) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as NSURL, nil) else {
            return nil
        }

        let options: [NSString: Any] = [
                // The maximum width and height in pixels of a thumbnail.
                kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                // Should include kCGImageSourceCreateThumbnailWithTransform: true in the options dictionary. Otherwise, the image result will appear rotated when an image is taken from camera in the portrait orientation.
                kCGImageSourceCreateThumbnailWithTransform: true
        ]
        
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }
}
