//
//  Sequence+Extensions.swift
//  untitled
//
//  Created by Mike Choi on 10/24/22.
//

import Foundation

extension Sequence {
    func sorted<T: Comparable>(keyPath: KeyPath<Element, T>) -> [Element] {
        return sorted { a, b in
            return a[keyPath: keyPath] < b[keyPath: keyPath]
        }
    }
}
