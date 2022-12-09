//
//  ImagePicker.swift
//  untitled
//
//  Created by Mike Choi on 10/12/22.
//

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

struct PHPickerPayload: Identifiable, Equatable {
    let id: UUID
    let results: [PHPickerResult]
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var pickerPayload: PHPickerPayload

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

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.pickerPayload = .init(id: UUID(), results: results)
            picker.dismiss(animated: true)
        }
    }
}

/*
 func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
     imageFetchCancellable?.cancel()
     
     picker.dismiss(animated: true)
   
     Task {
     }
     
//            if paths.count > 0 {
//                parent.assetPackage = PickedAssetPackage(id: UUID(), sources: paths.compactMap { $0 })
//            }
 }
 
 func resolvePaths(from results: [PHPickerResult]) async -> [PickedAssetPackage.Path?] {
     await withTaskGroup(of: PickedAssetPackage.Path?.self) { group in
         for result in results {
             group.addTask {
                 await self.resolvePath(from: result.itemProvider)
             }
         }
     }
 }
 
 func resolvePath(from provider: NSItemProvider) async -> PickedAssetPackage.Path? {
     withCheckedContinuation { continuation in
         provider.loadFileRepresentation(forTypeIdentifier: provider.registeredTypeIdentifiers.first ?? "") { url, err in
             if let url = url {
                 continuation.resume(returning: PickedAssetPackage.Path(url: url, itemProvider: provider))
             } else {
                 continuation.resume(returning: nil)
             }
         }
     }
 }
}
}

 */
