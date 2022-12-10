//
//  UIImage+Orientation.swift
//  untitled
//
//  Created by Mike Choi on 12/7/22.
//

import UIKit

extension UIImage {
    func fixOrientation() -> UIImage {
        if (imageOrientation == .up) {
            return self
        }
        
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        let rect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
        self.draw(in: rect)
        
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return normalizedImage
    }
}

extension UIImage {
    func imageResized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    func aspectFittedSize(_ maxSize: CGSize) -> CGSize {
        if size.height > size.width {
            let scale = maxSize.height / self.size.height
            let newWidth = self.size.width * scale
            return CGSize(width: newWidth, height: maxSize.height)
        } else {
            let scale = maxSize.width / self.size.width
            let newHeight = self.size.height * scale
            return CGSize(width: maxSize.width, height: newHeight)
        }
    }
}
