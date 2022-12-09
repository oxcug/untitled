//
//  ThemeSelectorView.swift
//  untitled
//
//  Created by Mike Choi on 11/11/22.
//

import SwiftUI

enum Theme: String, CaseIterable, Identifiable {
    case system
    case lightsOn = "lights on"
    case lightsOff = "lights off"
    
    var description: String {
        rawValue.description.capitalized
    }
    
    var id: String {
        rawValue
    }
    
    var colorScheme: ColorScheme? {
        switch self {
            case .system:
                return nil
            case .lightsOn:
                return .light
            case .lightsOff:
                return .dark
        }
    }
}

struct ThemeSelectorView: View {
    @AppStorage("theme") var currentTheme: Theme = .system
    
    var body: some View {
        List {
            ForEach(Theme.allCases) { theme in
                Button {
                    withAnimation {
                        currentTheme = theme
                    }
                } label: {
                    HStack {
                        Text(theme.description)
                            .font(.system(size: 15, weight: .regular, design: .default))
                            .foregroundColor(Color.bodyText)
                        
                        Spacer()
                        
                        Image(systemName: "checkmark")
                            .opacity(theme == currentTheme ? 1 : 0)
                            .foregroundColor(.bodyText)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("theme.")
        .preferredColorScheme(currentTheme.colorScheme)
    }
}


struct ThemeSelectorView_Preview: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ThemeSelectorView()
        }
    }
}
