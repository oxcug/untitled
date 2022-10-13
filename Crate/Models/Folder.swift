//
//  Folder.swift
//  Crate
//
//  Created by Mike Choi on 10/13/22.
//

import SwiftUI

struct Folder: Identifiable, Hashable {
    let id: String
    let emoji: String?
    let name: String
    let color: Color
    
    static let provided = [
        Folder(id: "a", emoji: "🍁", name: "Fall Outfits", color: .orange),
        Folder(id: "b", emoji: "❄️", name: "Winter Outfits", color: .blue),
        Folder(id: "c", emoji: "☕", name: "Cafes", color: .brown),
        Folder(id: "d", emoji: "🎵", name: "Music", color: .black),
        Folder(id: "e", emoji: "🔗", name: "Links", color: .blue),
    ]
}
