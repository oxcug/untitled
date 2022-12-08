//
//  ImagePicker.swift
//  untitled
//
//  Created by Mike Choi on 10/12/22.
//

import Combine
import PhotosUI
import SwiftUI

struct PickedAssetPackage: Identifiable {
    let id: UUID
    
    struct Path {
        let url: URL
        let itemProvider: NSItemProvider
    }
    
    let sources: [DataRetrievable]
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var assetPackage: PickedAssetPackage?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selection = .ordered
        config.selectionLimit = 100
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {

    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        var imageFetchCancellable: AnyCancellable?

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            let urlFutures = results.map {
                $0.itemProvider
            }.map { (provider: NSItemProvider) in
                Future<PickedAssetPackage.Path?, Never> { promise in
                    provider.loadFileRepresentation(forTypeIdentifier: provider.registeredTypeIdentifiers.first ?? "") { url, err in
                        if let url = url {
                            promise(.success(PickedAssetPackage.Path(url: url, itemProvider: provider)))
                        } else {
                            promise(.success(nil))
                        }
                    }
                }
            }
            
            imageFetchCancellable?.cancel()
            imageFetchCancellable = Publishers.MergeMany(urlFutures).collect().sink { [parent] paths in
                if paths.count > 0 {
                    parent.assetPackage = PickedAssetPackage(id: UUID(), sources: paths.compactMap { $0 })
                }
            }
        }
    }
}
