//
//  ImagePayload.swift
//  Crate
//
//  Created by Mike Choi on 10/13/22.
//

import UIKit

struct ImagePayload: Identifiable, Hashable {
    let id: UUID
    let original: UIImage
    let modified: UIImage?
}
