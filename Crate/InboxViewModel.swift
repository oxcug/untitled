//
//  InboxViewModel.swift
//  untitledShareExtension
//
//  Created by Mike Choi on 12/3/22.
//

import UIKit
import SwiftUI

struct InboxImage: Identifiable, Hashable {
    let id = UUID()
    let image: UIImage
    let filePath: URL
}

final class InboxViewModel: ObservableObject {
    @Published var thumbnails: [InboxImage] = []
    @Published var isLoading = false
    
    let imageLoadQueue = DispatchQueue(label: "com.mjc.crate.image.load")

    lazy var imageURLs: [URL] = {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.mjc.untitled") else {
            return []
        }
       
        return (try? fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)) ?? []
    }()
    
    func loadInboxThumbnails() {
        if isLoading {
            return
        }
      
        isLoading = true
        
        imageLoadQueue.async {
            let res = self.imageURLs.prefix(15).compactMap { path -> InboxImage? in
                guard let scaled = self.resize(url: path, maxPixelSize: 200) else {
                    return nil
                }
                return InboxImage(image: UIImage(cgImage: scaled), filePath: path)
            }
           
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.isLoading = false
                    self.thumbnails = res
                }
            }
        }
    }
    
    func clearInbox() {
        thumbnails = []
        
        imageURLs.forEach { url in
            try? FileManager.default.removeItem(at: url)
        }
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
