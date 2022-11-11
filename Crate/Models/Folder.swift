//
//  Folder.swift
//  untitled
//
//  Created by Mike Choi on 10/13/22.
//

import SwiftUI

struct Entry: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let textBoundingBoxes: [BoundingBox]
    let date: Date
    let original: UIImage
    let modified: UIImage?
    let colors: [MMCQ.Color]
    
    enum CodingKeys: CodingKey {
        case id, name, textBoundingBoxes, date, original, modified, colors
    }
}

extension Entry {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        textBoundingBoxes = try container.decode([BoundingBox].self, forKey: .textBoundingBoxes)
        date = try container.decode(Date.self, forKey: .date)
        colors = try container.decode([MMCQ.Color].self, forKey: .colors)
        
        let originalData = try container.decode(Data.self, forKey: .original)
        original = UIImage(data: originalData) ?? UIImage()
        
        if let modifiedData = try? container.decode(Data.self, forKey: .modified) {
            modified = UIImage(data: modifiedData)
        } else {
            modified = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(textBoundingBoxes, forKey: .textBoundingBoxes)
        try container.encode(date, forKey: .date)
        try container.encode(colors, forKey: .colors)
        try container.encode(original.pngData(), forKey: .original)
        if let modified = modified {
            try? container.encode(modified.pngData(), forKey: .modified)
        }
    }
}

struct Folder: Identifiable, Hashable {
    let id: UUID
    var name: String
    var emoji: String?
    let entries: [PictureEntry]
    let coreDataObject: PictureFolder?
}

extension Folder {
    init(coreDataObject cd: PictureFolder) {
        self.coreDataObject = cd
        id = cd.id ?? UUID()
        name = cd.name ?? ""
        emoji = cd.emoji ?? ""
        entries = (cd.entries?.array as? [PictureEntry])?.sorted(by: { lft, rht in
            (lft.date ?? .distantPast).compare(rht.date ?? .distantPast) == . orderedDescending
        }) ?? []
    }
}

extension Folder: Comparable, Equatable {
    static func < (lhs: Folder, rhs: Folder) -> Bool {
        lhs.name.compare(rhs.name) == .orderedAscending
    }
    
    var fullName: String {
        [emoji, name].compactMap { $0 }.joined(separator: " ")
    }
}
