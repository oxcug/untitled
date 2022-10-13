//
//  ImagePicker.swift
//  Crate
//
//  Created by Mike Choi on 10/12/22.
//

import Combine
import PhotosUI
import SwiftUI

struct ImagePayload: Identifiable {
    let id: UUID
    let original: UIImage
    let modified: UIImage?
}

struct ImagesPayload: Identifiable {
    let id: UUID
    let images: [ImagePayload]
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var imagesPayload: ImagesPayload?

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
            
            let imageLoadFutures = results.map {
                $0.itemProvider
            }.filter {
                $0.canLoadObject(ofClass: UIImage.self)
            }.map { (provider: NSItemProvider) in
                Future<UIImage?, Never> { promise in
                    provider.loadObject(ofClass: UIImage.self) { image, err in
                        promise(.success(image as? UIImage))
                    }
                }
            }
            
            imageFetchCancellable?.cancel()
            imageFetchCancellable = Publishers.MergeMany(imageLoadFutures).collect().sink { [parent] images in
                parent.imagesPayload = ImagesPayload(id: UUID(), images: images
                    .compactMap { $0 }
                    .map { ImagePayload(id: UUID(), original: $0, modified: ImageProcessor.shared.process(image: $0))}
                )
            }
        }
    }
}
