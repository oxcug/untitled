//
//  PictureEntryDetailViewModel.swift
//  untitled
//
//  Created by Mike Choi on 11/25/22.
//

import Combine
import UIKit

final class PictureEntryDetailViewModel: ObservableObject {
    lazy var relativeDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .short
        df.doesRelativeDateFormatting = true
        return df
    }()
    
    var payload: DetailPayload = .dummy {
        didSet {
            reload(payload: payload)
        }
    }
    
    @Published var cur: EntryEntity = .init(id: UUID(), entry: nil)
    @Published var entries: [EntryEntity] = []
    @Published var images: [UUID: UIImage] = [:]
    
    @Published var name = "Untitled"
    @Published var description: String?
    @Published var folderName = "Untitled"
    @Published var dateString = "The Void"
    @Published var palette: [UIColor] = []
    @Published var paletteCache: [UUID: [UIColor]] = [:]
    
    @Published var backgroundColor: UIColor = .black
    
    func reset() {
        backgroundColor = .black
        entries = []
    }
    
    func deleteCurrent() {
        guard let curIdx = entries.firstIndex(of: cur) else {
           return
        }
        
        backgroundColor = .black
        entries.remove(at: curIdx)
        
        let nextIdx: Int
        switch curIdx {
            case let idx where idx > entries.count - 1:
                nextIdx = idx - 1
            case let idx where idx == 0:
                nextIdx = 0
            default:
                nextIdx = curIdx - 1
        }
        
        if entries.count > 0 {
            cur = entries[nextIdx]
        } else {
            cur = .init(id: UUID(), entry: nil)
        }
        
        reload(entry: cur)
    }
    
    func reload(payload: DetailPayload) {
        guard let entry = payload.detail,
              let folder = payload.folder,
              let currentIndexInFolder = folder.entries.firstIndex(of: entry) else {
            return
        }
        
        folderName = folder.fullName
        
        let existingEntries = folder.entries.map { EntryEntity(id: $0.id ?? UUID(), entry: $0) }
        entries = existingEntries.dropFirst(Int(currentIndexInFolder)) + existingEntries.dropLast(existingEntries.count - Int(currentIndexInFolder))
        images = Dictionary(uniqueKeysWithValues: entries.map {
            ($0.id, ImageStorage.shared.loadImage(named: $0.modified ?? $0.original) ?? UIImage())
        })
        
        if let first = entries.first {
            reload(entry: first)
            cur = first
        }
    }
    
    func reload(entry: EntryEntity)  {
        palette = loadPalette(entry: entry)
        backgroundColor = palette.first ?? .black
        description = entry.detail
        
        name = entry.name
        if name.count == 0 {
            name = "Untitled"
        }
        
        if let date = entry.date {
            dateString = relativeDateFormatter.string(from: date)
        } else {
            dateString = "the void"
        }
    }
    
    func loadPalette(entry: EntryEntity) -> [UIColor] {
        if let cachedPalette = paletteCache[entry.id] {
            return cachedPalette
        } else {
            let colorStrings = entry.colors ?? []
            let palette = colorStrings.map { MMCQ.Color(rgbID: $0).makeUIColor() }
            paletteCache[entry.id] = palette
            return palette
        }
    }
}
