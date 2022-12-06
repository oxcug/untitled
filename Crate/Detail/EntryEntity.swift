//
//  EntryEntity.swift
//  untitled
//
//  Created by Mike Choi on 11/28/22.
//

import Foundation
import SwiftUI

struct EntryEntity: Identifiable, Equatable, Hashable {
    let id: UUID
    let entry: PictureEntry?
    let hasModifiedImage: Bool
    
    init(id: UUID, entry: PictureEntry?) {
        self.id = id
        self.entry = entry
        self.hasModifiedImage = (entry?.modified != nil)
    }
    
    var original: String? {
        entry?.original
    }
    
    var modified: String? {
        entry?.modified
    }
    
    var colors: [String]? {
        entry?.colors
    }
    
    var name: String {
        entry?.name ?? "Untitled"
    }
    
    var date: Date? {
        entry?.date
    }
    
    var detail: String? {
        guard let description = entry?.detailText else {
            return nil
        }
        
        let strippedDescription = description.reversed().trimmingPrefix { elem in
            elem == "\n"
        }
        return String(strippedDescription.reversed())
    }
}
