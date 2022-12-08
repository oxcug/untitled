//
//  ImageStorage.swift
//  untitled
//
//  Created by Mike Choi on 10/13/22.
//

import UIKit
import SwiftUI
import Photos

final class ImageStorage: ObservableObject {
    static let shared = ImageStorage()
    
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    let fileManager: FileManager
    let documentsURL: URL
    
    var cacheTable: [String: UIImage] = [:]
    var imageCacheManager = PHCachingImageManager()
    
    private init() {
        fileManager = FileManager.default
        documentsURL = try! fileManager.url(for: .libraryDirectory, in: .allDomainsMask, appropriateFor: nil, create: true)
    }
    
    func url(for entry: PictureEntry) -> URL {
        documentsURL.appendingPathComponent(entry.modified ?? entry.original ?? "")
    }
    
    func original(for entry: PictureEntry?) -> URL {
        documentsURL.appendingPathComponent(entry?.original ?? "")
    }
    
    func modifiedURL(for entry: PictureEntry) -> URL {
        documentsURL.appendingPathComponent(entry.modified ?? "")
    }
    
    func loadImage(named fileName: String?) -> UIImage? {
        guard let fileName = fileName else {
            return nil
        }
        
        if let cached = cacheTable[fileName] {
            return cached
        }
        
        let fileURL = documentsURL.appendingPathComponent(fileName)
        do {
            let imageData = try Data(contentsOf: fileURL)
            let image = UIImage(data: imageData)?.fixOrientation()
            cacheTable[fileName] = image
            return image
        } catch {
            return nil
        }
    }
    
    func write(_ image: UIImage?, entryID: UUID, isOriginal: Bool) -> String? {
        guard let pngData = image?.pngData() else {
            return nil
        }
       
        let name = "\(entryID.uuidString)-\(isOriginal ? "original" : "modified").png"
        let fileURL = documentsURL.appendingPathComponent(name)
        try! pngData.write(to: fileURL)
        return name
    }
}
