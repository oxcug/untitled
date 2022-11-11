//
//  PictureEntryViewModel.swift
//  untitled
//
//  Created by Mike Choi on 10/24/22.
//

import UIKit

final class PictureEntryViewModel: ObservableObject {
    lazy var relativeDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .short
        df.doesRelativeDateFormatting = true
        return df
    }()
    
    func image(for entry: PictureEntry) -> UIImage {
        ImageStorage.shared.loadImage(named: entry.modified ?? entry.original) ?? UIImage()
    }
    
    func name(for entry: PictureEntry) -> String {
        entry.name ?? "Untitled"
    }
    
    func dateString(for entry: PictureEntry) -> String {
        if let date = entry.date {
            return relativeDateFormatter.string(from: date)
        } else {
            return "Unknown"
        }
    }
    
    func palette(for entry: PictureEntry) -> [UIColor] {
        entry.colors as? [UIColor] ?? []
    }
}
