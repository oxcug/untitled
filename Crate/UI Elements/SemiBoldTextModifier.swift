//
//  SemiBoldTextModifier.swift
//  untitled
//
//  Created by Mike Choi on 11/11/22.
//

import SwiftUI

struct SemiBoldBodyTextModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 15, weight: .semibold, design: .default))
            .foregroundColor(Color.bodyText)
    }
}

struct BodyTextModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 15, weight: .regular, design: .default))
            .foregroundColor(Color.bodyText)
    }
}

struct NavigationBarTextModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 17, weight: .semibold, design: .default))
            .foregroundColor(Color.bodyText)
    }
}
