//
//  HomeViewModel.swift
//  untitled
//
//  Created by Mike Choi on 10/24/22.
//

import UIKit
import Combine
import SwiftUI

final class HomeViewModel: ObservableObject {
    lazy var relativeDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .short
        df.doesRelativeDateFormatting = true
        return df
    }()
    
    @Published var fetchingAssets = false
    var fetchStream: AnyCancellable?
    
    func loadAssetDetails(pickerPayload: PHPickerPayload, completion: @escaping (PickedAssetPackage) -> ()) {
        fetchingAssets = true
        fetchStream?.cancel()
        
        let urlFutures = pickerPayload.results.map {
            $0.itemProvider
        }.map { (provider: NSItemProvider) in
            Future<PickedAssetPackage.Path?, Never> { promise in
                provider.loadInPlaceFileRepresentation(forTypeIdentifier: provider.registeredTypeIdentifiers.first ?? "") { url, ok, err in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        if let url = url {
                            promise(.success(PickedAssetPackage.Path(url: url, itemProvider: provider)))
                        } else {
                            promise(.success(nil))
                        }
                    }
                }
            }
        }
        
        fetchStream = Publishers.MergeMany(urlFutures)
            .collect()
            .receive(on: RunLoop.main)
            .sink { [weak self] paths in
                withAnimation(.easeInOut(duration: 0.2)) {
                    self?.fetchingAssets = false
                }
                
                if paths.count > 0 {
                    completion(PickedAssetPackage(id: UUID(), sources: paths.compactMap { $0 }))
                }
            }
    }
        
    func image(for entry: PictureEntry) -> UIImage {
        ImageStorage.shared.loadImage(named: entry.modified ?? entry.original) ?? UIImage()
    }
    
    func name(for entry: PictureEntry) -> String {
        let name = entry.name ?? "Untitled"
        return name.count == 0 ? "Untitled" : name
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
