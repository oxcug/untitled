//
//  FolderStorage.swift
//  Crate
//
//  Created by Mike Choi on 10/13/22.
//

import UIKit
import SwiftUI

final class FolderStorage: ObservableObject {
    static let shared = FolderStorage()
    
    @Published var folders: [Folder] = []
    
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    let fileManager: FileManager
    let documentsURL: URL
    
    private init() {
        fileManager = FileManager.default
        documentsURL = try! fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        
        let folderURLs = try! fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
        folders = folderURLs.compactMap { url -> Folder? in
            guard !url.absoluteString.contains(".DS_Store") else {
                return nil
            }
            guard let data = try? Data(contentsOf: url) else {
                return nil
            }
            return try? decoder.decode(Folder.self, from: data)
        }
        
        if folders.isEmpty {
            createFolder(name: "Favorites", emoji: "⭐", color: .yellow, entries: [])
        }
    }
    
    func add(entry: Entry, to folder: Folder) {
        guard let folderIdx = folders.firstIndex(of: folder) else {
            return
        }
        
        let newFolder = Folder(id: folder.id,
                               name: folder.name,
                               emoji: folder.emoji,
                               color: folder.color,
                               entries: folder.entries + [entry])
        
        folders[folderIdx] = newFolder
        write(newFolder)
    }
    
    func createFolder(name: String, emoji: String, color: Color, entries: [Entry]) {
        let newFolder = Folder(id: UUID().uuidString, name: name, emoji: emoji, color: color, entries: entries)
        write(newFolder)
        folders.append(newFolder)
    }
    
    func write(_ folder: Folder) {
        let fileURL = documentsURL.appendingPathComponent("\(folder.id)")
        let data = try! encoder.encode(folder)
        try! data.write(to: fileURL)
    }
}
