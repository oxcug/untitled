//
//  UIImage+Extensions.swift
//  Crate
//
//  Created by Mike Choi on 10/12/22.
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
