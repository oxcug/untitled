//
//  MoreText.swift
//  untitled
//
//  Created by Mike Choi on 11/25/22.
//

import SwiftUI

struct MoreText: View {
    let text: String
    let lineLimit: Int = 2
    @State var didOverflow = false
    @Binding var backgroundColor: UIColor
    
    var didTapMore: (() -> ())?
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Text(text)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.leading)
                .lineLimit(lineLimit, reservesSpace: false)
                .font(.system(size: 17, weight: .regular, design: .default))
            
            if didOverflow {
                Button {
                    didTapMore?()
                } label: {
                    Text("MORE")
                        .font(.system(size: 14, weight: .semibold, design: .default))
                        .foregroundColor(.white)
                        .background(Color(uiColor: backgroundColor))
                        .shadow(color: Color(uiColor: backgroundColor), radius: 3, x: -10, y: 0)
                }
            }
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .onChange(of: text, perform: { newValue in
            calculateMorePresence(text: newValue)
        })
        .task {
            calculateMorePresence(text: text)
        }
    }
    
    func calculateMorePresence(text: String) {
        let font = UIFont.systemFont(ofSize: 17)
        let constraintRect = CGSize(width: UIScreen.main.bounds.width, height: .greatestFiniteMagnitude)
        let boundingBox = text.boundingRect(with: constraintRect,
                                            options: .usesLineFragmentOrigin,
                                            attributes: [NSAttributedString.Key.font: font],
                                            context: nil)
        let height = Int(ceil(boundingBox.height))
        didOverflow = (height / Int(font.lineHeight)) >= lineLimit
    }
}

struct MoreText_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading, spacing: 30) {
            MoreText(text: "hello world", backgroundColor: .constant(.black))
            
            MoreText(text: "hello worldhello worldhello worldhello worldhello worldhello worldhello worldhello worldhello worldhello world", backgroundColor: .constant(.black))
        }
        .frame(maxHeight: .infinity)
        .background(.black)
    }
}
