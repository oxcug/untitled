//
//  Modal.swift
//  Crate
//
//  Created by Mike Choi on 11/8/22.
//

import UIKit
import SwiftUI

extension View {
    func presentFullScreenModal<Content: View, Item: Equatable>(item: Binding<Item>, @ViewBuilder content: @escaping (Item) -> Content) -> some View {
        onChange(of: item.wrappedValue) { value in
            let topMostController = self.topMostController()
            if (!topMostController.isPanModalPresented) {
                DispatchQueue.main.async {
                    let rootView = content(value)
                    let host = FullScreenHostingController(rootView: rootView)
                    topMostController.presentPanModal(host)
                }
            }
        }
    }
    
    func presentModal<Content: View>(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) -> some View {
        onChange(of: isPresented.wrappedValue) { isPresented in
            let topMostController = self.topMostController()
            
            if (!topMostController.isPanModalPresented) {
                DispatchQueue.main.async {
                    let rootView = content()
                    let host = PartialModalHostingController(rootView: rootView)
                    topMostController.presentPanModal(host)
                }
            } else {
                topMostController.dismiss(animated: true)
            }
        }
    }
    
    func topMostController() -> UIViewController {
        var topController = UIApplication.shared.windows.first!.rootViewController!
        while (topController.presentedViewController != nil) {
            topController = topController.presentedViewController!
        }
        return topController
    }
}
