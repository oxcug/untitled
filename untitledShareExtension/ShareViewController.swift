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

@objc(ShareExtensionViewController)
class ShareViewController: UIViewController {
    
    var streams = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        setupNavBar()
        
        Task {
            let images = await self.loadSharedFiles().compactMap { $0 }
            let controller = UIHostingController(rootView: ShareView(images: images, openApp: {
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
            
            images.forEach { saveImage($0) }
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
    
    private func loadSharedFiles() async -> [UIImage?] {
        return await withCheckedContinuation { continuation in
            let attachments = (self.extensionContext?.inputItems.first as? NSExtensionItem)?.attachments ?? []
            
            let futures = attachments.map { attachment in
                loadItem(from: attachment)
            }
            
            Publishers.MergeMany(futures).compactMap { $0 }
                .collect()
                .sink { imgs in
                    continuation.resume(returning: imgs)
                }
                .store(in: &streams)
        }
    }
}

extension ShareViewController {
    private func loadItem(from itemProvider: NSItemProvider) -> Future<UIImage?, Never> {
        Future<UIImage?, Never> { promise in
            guard let registeredTypeId = itemProvider.registeredTypeIdentifiers.first,
                    itemProvider.hasItemConformingToTypeIdentifier(registeredTypeId) else {
                promise(.success(nil))
                return
            }
            
            itemProvider.loadItem(forTypeIdentifier: registeredTypeId, options: nil) { (data, error) in
                guard error == nil else {
                    promise(.success(nil))
                    return
                }
                
                if let url = data as? URL, let imageData = try? Data(contentsOf: url) {
                    promise(.success(UIImage(data: imageData)))
                } else if let image = data as? UIImage {
                    promise(.success(image))
                } else {
                    promise(.success(nil))
                }
            }
        }
    }
    
    private func saveImage(_ image: UIImage) {
        let documentsDirectory = FileManager().containerURL(forSecurityApplicationGroupIdentifier: "group.com.mjc.untitled")
        guard let archiveURL = documentsDirectory?.appendingPathComponent("\(UUID()).png") else {
            return
        }
        
        try? image.pngData()?.write(to: archiveURL)
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
