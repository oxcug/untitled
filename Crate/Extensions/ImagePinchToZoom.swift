//
//  ImagePinchToZoom.swift
//  untitled
//
//  Created by Mike Choi on 11/7/22.
//

import SwiftUI
import UIKit

extension View {
    func addPinchToZoom(isZooming: Binding<Bool>) -> some View {
        PinchZoomContext(isZooming: isZooming) {
            self
        }
    }
}

extension View {
    func addPinchToZoom(isZooming: Binding<Bool>, offset: Binding<CGPoint>, scale: Binding<CGFloat>, scalePosition: Binding<CGPoint>) -> some View {
        PassthroughPinchZoomContext(isZooming: isZooming, offset: offset, scale: scale, scalePosition: scalePosition) {
            self
        }
    }
}

struct PassthroughPinchZoomContext<Content: View>: View {

    var content: Content
    
    init(isZooming: Binding<Bool>, offset: Binding<CGPoint>, scale: Binding<CGFloat>, scalePosition: Binding<CGPoint>, @ViewBuilder content: @escaping () -> Content) {
        self._isZooming = isZooming
        self._offset = offset
        self._scale = scale
        self._scalePoisition = scalePosition
        self.content = content()
    }
    
    @Binding var offset: CGPoint
    @Binding var scale: CGFloat
    @Binding var scalePoisition: CGPoint
    @Binding var isZooming: Bool
    
    var body: some View {
        content
            .offset(x: offset.x, y: offset.y)
            .overlay(
                GeometryReader { proxy in
                    let size = proxy.size
                    ZoomGesture(size: size, scale: $scale, offset: $offset, scalePosition: $scalePoisition)
                }
            )
            .scaleEffect(1 + (scale < 0 ? 0 : scale), anchor: .init(x: scalePoisition.x, y: scalePoisition.y))
            .zIndex(scale != 0 ? 1000 : 0)
            .onChange(of: scale) { newValue in
                isZooming = (scale != 0 || offset != .zero)
                
                if scale == -1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        scale = 0
                    }
                }
            }
    }
}

struct PinchZoomContext<Content: View>: View {

    var content: Content
    
    init(isZooming: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) {
        self._isZooming = isZooming
        self.content = content()
    }
    
    @State var offset: CGPoint = .zero
    @State var scale: CGFloat = 0
    @State var scalePoisition: CGPoint = .zero
    @Binding var isZooming: Bool
    
    var body: some View {
        content
            .offset(x: offset.x, y: offset.y)
            .overlay(
                GeometryReader { proxy in
                    let size = proxy.size
                    ZoomGesture(size: size, scale: $scale, offset: $offset, scalePosition: $scalePoisition)
                }
            )
            .scaleEffect(1 + (scale < 0 ? 0 : scale), anchor: .init(x: scalePoisition.x, y: scalePoisition.y))
            .zIndex(scale != 0 ? 1000 : 0)
            .onChange(of: scale) { newValue in
                isZooming = (scale != 0 || offset != .zero)
                
                if scale == -1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        scale = 0
                    }
                }
            }
    }
}

struct ZoomGesture: UIViewRepresentable {
    var size: CGSize
    
    @Binding var scale: CGFloat
    @Binding var offset: CGPoint
    @Binding var scalePosition: CGPoint
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        
        let pinch = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handlePinch(sender:)))
        view.addGestureRecognizer(pinch)
        
        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handlePan(sender:)))
        pan.delegate = context.coordinator
        view.addGestureRecognizer(pan)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
    }
    
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var parent: ZoomGesture
        
        init(parent: ZoomGesture) {
            self.parent = parent
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            true
        }
        
        @objc
        func handlePinch(sender: UIPinchGestureRecognizer) {
            if sender.state == .began || sender.state == .changed {
                parent.scale = sender.scale - 1
                
                let scalePoint = CGPoint(x: sender.location(in: sender.view).x / sender.view!.frame.size.width,
                                         y: sender.location(in: sender.view).y / sender.view!.frame.size.height)
               
                parent.scalePosition = (parent.scalePosition == .zero ? scalePoint : parent.scalePosition)
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    parent.scale = -1
                    parent.scalePosition = .zero
                }
            }
        }
        
        @objc
        func handlePan(sender: UIPanGestureRecognizer) {
            sender.maximumNumberOfTouches = 2
            
            if sender.state == .began || sender.state == .changed && parent.scale > 0 {
                if let view = sender.view {
                    let translation = sender.translation(in: view)
                    parent.offset = translation
                }
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    parent.offset = .zero
                    parent.scalePosition = .zero
                }
            }
        }
    }
}
