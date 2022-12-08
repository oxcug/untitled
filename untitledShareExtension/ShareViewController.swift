//
//  ShareViewController.swift
//  untitledShareExtension
//
//  Created by Mike Choi on 11/28/22.
//

import Combine
import UIKit
import UniformTypeIdentifiers
import MobileCoreServices
import SwiftUI

enum ImageRepresentation {
    case url(URL)
    case data(Data)
}

@objc(ShareExtensionViewController)
class ShareViewController: UIViewController {
   
    let saveQueue = DispatchQueue(label: "com.mjc.crate.save.image", qos: .background, autoreleaseFrequency: .workItem)
    var streams = Set<AnyCancellable>()
    var resizedImageStream = CurrentValueSubject<[UIImage], Never>([])
    
    lazy var documentsDirectory: URL? = {
        FileManager().containerURL(forSecurityApplicationGroupIdentifier: "group.com.mjc.untitled")
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        setupNavBar()
        
        let controller = UIHostingController(rootView: ShareView(imagesStream: resizedImageStream, openApp: {
            _ = self.openURL(URL(string: "untitled://inbox")!)
        }))
        let swiftUIView = controller.view!
        swiftUIView.translatesAutoresizingMaskIntoConstraints = false
        addChild(controller)
        view.addSubview(swiftUIView)
        controller.didMove(toParent: self)
        
        NSLayoutConstraint.activate([
            swiftUIView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            swiftUIView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            swiftUIView.topAnchor.constraint(equalTo: view.topAnchor),
            swiftUIView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
       
        Task {
            let images = await loadSharedFiles()
            resizedImageStream.send(images.compactMap { $0 })
        }
    }
    
    private func setupNavBar() {
        navigationItem.title = "untitled."
    }
    
    @objc private func doneAction() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
    
    @objc func openURL(_ url: URL) -> Bool {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                return application.perform(#selector(openURL(_:)), with: url) != nil
            }
            responder = responder?.next
        }
        return false
    }
    
    private func loadSharedFiles() async -> [UIImage] {
        let attachments = (self.extensionContext?.inputItems.first as? NSExtensionItem)?.attachments ?? []
        var resizedImages = [UIImage]()
        
        for attachment in attachments {
            guard let imageRepresentation = await loadItem(from: attachment) else {
                continue
            }
            
            autoreleasepool {
                saveImage(imageRepresentation)
            }
            
            if resizedImages.count > 7 {
                continue
            }
          
            if let resized = resize(imageRepresentation: imageRepresentation, maxPixelSize: 100) {
                resizedImages.append(UIImage(cgImage: resized))
            }
        }
        
        return resizedImages
    }
    
    func resize(imageRepresentation: ImageRepresentation, maxPixelSize: Int) -> CGImage? {
        let source: CGImageSource?
        
        switch imageRepresentation {
            case .url(let url):
                source = CGImageSourceCreateWithURL(url as NSURL, nil)
            case .data(let data):
                source = CGImageSourceCreateWithData(data as NSData, nil)
        }
        
        guard let imageSource = source else {
            return nil
        }

        var scaledImage: CGImage?
        let options: [NSString: Any] = [
                // The maximum width and height in pixels of a thumbnail.
                kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                // Should include kCGImageSourceCreateThumbnailWithTransform: true in the options dictionary. Otherwise, the image result will appear rotated when an image is taken from camera in the portrait orientation.
                kCGImageSourceCreateThumbnailWithTransform: true
        ]
        
        scaledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary)
        return scaledImage
    }
}

extension ShareViewController {
    private func loadItem(from itemProvider: NSItemProvider) async -> ImageRepresentation? {
        guard let registeredTypeId = itemProvider.registeredTypeIdentifiers.first,
              itemProvider.hasItemConformingToTypeIdentifier(registeredTypeId) else {
            return nil
        }
        
        return await withCheckedContinuation { continuation in
            itemProvider.loadItem(forTypeIdentifier: registeredTypeId, options: nil) { (data, error) in
                guard error == nil else {
                    continuation.resume(returning: nil)
                    return
                }
                
                autoreleasepool {
                    if let url = data as? URL {
                        continuation.resume(returning: ImageRepresentation.url(url))
                    } else if let image = data as? UIImage, let jpeg = image.jpegData(compressionQuality: 1) {
                        continuation.resume(returning: ImageRepresentation.data(jpeg))
                    } else {
                        continuation.resume(returning: nil)
                    }
                }
            }
        }
    }
    
    private func saveImage(_ imageRepresentation: ImageRepresentation) {
        guard let archiveURL = documentsDirectory?.appendingPathComponent("\(UUID()).jpg") else {
            return
        }
       
        saveQueue.async {
            switch imageRepresentation {
                case .url(let url):
                    try? Data(contentsOf: url).write(to: archiveURL)
                case .data(let data):
                    try? data.write(to: archiveURL)
            }
        }
    }
}

extension Future where Failure == Error {
    convenience init(asyncFunc: @escaping () async throws -> Output) {
        self.init { promise in
            Task {
                do {
                    let result = try await asyncFunc()
                    promise(.success(result))
                } catch {
                    promise(.failure(error))
                }
            }
        }
    }
}
