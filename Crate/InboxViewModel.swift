//
//  InboxViewModel.swift
//  untitledShareExtension
//
//  Created by Mike Choi on 12/3/22.
//

import UIKit
import SwiftUI

struct IdentifiableImage: Identifiable, Hashable {
    let id = UUID()
    let image: UIImage
}

final class InboxViewModel: ObservableObject {
    @Published var images: [IdentifiableImage] = []

    func loadInbox() {
        images = [.init(named: "outfit.jpeg")!, .init(named: "IMG_2923.PNG")!, .init(named: "IMG_2923.PNG")!,.init(named: "IMG_2923.PNG")!,.init(named: "IMG_2923.PNG")!,.init(named: "IMG_2923.PNG")!,.init(named: "IMG_2923.PNG")!,.init(named: "IMG_2923.PNG")!,.init(named: "IMG_2923.PNG")!, .init(named: "outfit.jpeg")!, .init(named: "outfit.jpeg")!, .init(named: "outfit.jpeg")!, .init(named: "outfit.jpeg")!].map { IdentifiableImage(image: $0) }
        /*
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.mjc.untitled"),
              let files = try? fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil) else {
            return
        }
        
        images = files.compactMap {
            guard let imageData = try? Data(contentsOf: $0) else {
                return nil
            }
            
            return UIImage(data: imageData)
        }
         */
    }
}
