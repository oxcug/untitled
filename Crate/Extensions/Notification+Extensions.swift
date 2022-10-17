//
//  Notification+Extensions.swift
//  Crate
//
//  Created by Mike Choi on 10/12/22.
//

import UIKit
import Combine

extension Notification {
    var keyboardHeight: CGFloat {
        return (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0
    }
}

extension Publishers {
    // 1.
    static var keyboardHeight: AnyPublisher<CGFloat, Never> {
        let willShow = NotificationCenter.default.publisher(for: UIApplication.keyboardDidShowNotification)
            .map { $0.keyboardHeight }
        
        let willHide = NotificationCenter.default.publisher(for: UIApplication.keyboardDidHideNotification)
            .map { _ in CGFloat(0) }
        
        // 3.
        return MergeMany(willShow, willHide)
            .eraseToAnyPublisher()
    }
    
    static var keyboardWillBeVisible: AnyPublisher<Bool, Never> {
        let willShow = NotificationCenter.default.publisher(for: UIApplication.keyboardWillShowNotification)
            .map { _ in true }
        
        let willHide = NotificationCenter.default.publisher(for: UIApplication.keyboardWillHideNotification)
            .map { _ in false }
        
        return MergeMany(willShow, willHide)
            .eraseToAnyPublisher()
    }

}
