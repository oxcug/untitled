//
//  LineSegmentedControl.swift
//  untitled
//
//  Created by Mike Choi on 12/6/22.
//

import SwiftUI

struct RectPreferenceKey: PreferenceKey
{
    typealias Value = CGRect
    
    static var defaultValue = CGRect.zero
    
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

// MARK: -

struct UnderlineModifier: ViewModifier {
    var selectedIndex: Int
    let frames: [CGRect]
    let color: Color
    
    func body(content: Content) -> some View {
        content
            .background(
                Rectangle()
                    .fill(color)
                    .frame(width: frames[selectedIndex].width, height: 4)
                    .offset(x: frames[selectedIndex].minX - frames[0].minX), alignment: .bottomLeading
            )
            .animation(.easeInOut(duration: 0.18), value: selectedIndex)
    }
}

// MARK: -

struct LineSegmentedView: View {
    @Binding private var selectedIndex: Int
    
    @State private var frames: Array<CGRect>
    @State private var backgroundFrame = CGRect.zero
    
    private let titles: [String]
    let color: Color
    
    init(color: Color, selectedIndex: Binding<Int>, titles: [String]) {
        self.color = color
        self._selectedIndex = selectedIndex
        self.titles = titles
        frames = Array<CGRect>(repeating: .zero, count: titles.count)
    }
    
    var body: some View {
        VStack {
            SegmentedControlButtonView(color: color, selectedIndex: $selectedIndex, frames: $frames, backgroundFrame: $backgroundFrame, titles: titles)
        }
        .background(
            GeometryReader { geoReader in
                Color.clear.preference(key: RectPreferenceKey.self, value: geoReader.frame(in: .global))
                    .onPreferenceChange(RectPreferenceKey.self) {
                        self.setBackgroundFrame(frame: $0)
                    }
            }
        )
    }
    
    private func setBackgroundFrame(frame: CGRect) {
        backgroundFrame = frame
    }
}

private struct SegmentedControlButtonView: View {
    @Binding private var selectedIndex: Int
    @Binding private var frames: [CGRect]
    @Binding private var backgroundFrame: CGRect
    
    private let titles: [String]
    let color: Color
    
    init(color: Color, selectedIndex: Binding<Int>, frames: Binding<[CGRect]>, backgroundFrame: Binding<CGRect>, titles: [String])
    {
        _selectedIndex = selectedIndex
        _frames = frames
        _backgroundFrame = backgroundFrame
        
        self.color = color
        self.titles = titles
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(titles.indices, id: \.self) { index in
                Button(action: { selectedIndex = index }) {
                    HStack {
                        Text(titles[index])
                            .font(.system(size: 15, weight: .semibold, design: .default))
                    }
                }
                .buttonStyle(CustomSegmentButtonStyle())
                .background(
                    GeometryReader { geoReader in
                        Color.clear.preference(key: RectPreferenceKey.self, value: geoReader.frame(in: .global))
                            .onPreferenceChange(RectPreferenceKey.self) {
                                self.setFrame(index: index, frame: $0)
                            }
                    }
                )
            }
        }
        .modifier(UnderlineModifier(selectedIndex: selectedIndex, frames: frames, color: color))
    }
    
    private func setFrame(index: Int, frame: CGRect) {
        self.frames[index] = frame
    }
}

private struct CustomSegmentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .padding(EdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 20))
            .foregroundColor(configuration.isPressed ? .secondary : .primary)
    }
}

struct SegmentedView_Previews: PreviewProvider {
    @State static var idx = 0
    
    static var previews: some View {
        LineSegmentedView(color: .blue, selectedIndex: $idx, titles: Method.allCases.map { $0.description })
    }
}
