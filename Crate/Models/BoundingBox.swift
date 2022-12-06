//
//  BoundingBox.swift
//  untitled
//
//  Created by Mike Choi on 10/24/22.
//

import Foundation

public class BoundingBox: NSObject, Identifiable, Codable, NSSecureCoding {
    public let id: UUID
    public let confidence: Float?
    public let box: CGRect
    public let string: String
    
    public static var supportsSecureCoding: Bool = true
    
    public static var filteredWords: Set<String> = [
        "0 QV"
    ]
    
    init(id: UUID, confidence: Float?, box: CGRect, string: String) {
        self.id = id
        self.confidence = confidence
        self.box = box
        self.string = string
    }
    
    public required init?(coder: NSCoder) {
        id = coder.decodeObject(forKey: "id") as! UUID
        confidence = coder.decodeFloat(forKey: "confidence")
        box = coder.decodeCGRect(forKey: "box")
        string = coder.decodeObject(forKey: "string") as! String
    }
    
    public func encode(with coder: NSCoder) {
        coder.encode(id, forKey: "id")
        coder.encode(confidence ?? 0, forKey: "confidence")
        coder.encode(box, forKey: "box")
        coder.encode(string, forKey: "string")
    }
    
    var area: CGFloat {
        box.size.area
    }
    
    var semiConfident: Bool {
        (confidence ?? 0) >= 0.5 && area > 800 && !BoundingBox.filteredWords.contains(string) && string.count > 1
    }
}
