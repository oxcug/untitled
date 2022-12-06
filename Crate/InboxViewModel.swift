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
    @Published var images: [InboxImage] = []
    var isLoading = false

    var imageURLs: [URL]? {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.mjc.untitled") else {
            return nil
        }
       
        return try? fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
    }
    
    func loadInbox() {
        if isLoading {
            return
        }
        
        images = imageURLs?.compactMap { path -> InboxImage? in
            guard let imageData = try? Data(contentsOf: path), let image = UIImage(data: imageData) else {
                return nil
            }
            
            return InboxImage(image: image, filePath: path)
        } ?? []
        
        isLoading = false
    }
    
    func clearInbox() {
        images = []
        
        imageURLs?.forEach { url in
            try? FileManager.default.removeItem(at: url)
        }
    }
}
