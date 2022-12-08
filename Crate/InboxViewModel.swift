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
    @Published var thumbnails: [URL] = []
    
    let imageLoadQueue = DispatchQueue(label: "com.mjc.crate.image.load")

    lazy var imageURLs: [URL] = {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.mjc.untitled") else {
            return []
        }
       
        return (try? fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)) ?? []
    }()
    
    func loadInboxThumbnails() {
        thumbnails = imageURLs
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
