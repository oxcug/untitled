//
//  AppIconSelectorView.swift
//  untitled
//
//  Created by Mike Choi on 11/10/22.
//

import SwiftUI

enum AppIcon: String, CaseIterable, Identifiable {
    case untitled
    case pabloBlue = "pablo blue"
    case internationalOrange = "international orange"
    case forestGreen = "forest green"
    
    var id: String {
        rawValue
    }
    
    var name: String {
        rawValue.capitalized
    }
    
    var iconImageName: String? {
        if self == .untitled {
            return nil
        } else {
            return rawValue.replacingOccurrences(of: " ", with: ".")
        }
    }
    
    var previewName: String {
        rawValue.replacingOccurrences(of: " ", with: ".").appending(".preview")
    }
    
    var hex: String {
        switch self {
            case .untitled:
                return "#FFFFFF"
            case .pabloBlue:
               return "#0000F3"
            case .internationalOrange:
                return "#FF4F00"
            case .forestGreen:
                return "#29613D"
        }
    }
}

struct AppIconSelectorView: View {
    @AppStorage("active.icon") var activeIcon: AppIcon = .untitled
    
    var body: some View {
        List {
            Section(header: Text("").frame(height: 0)) {
                ForEach(AppIcon.allCases) { icon in
                    Button {
                        Task.init {
                            await setIcon(icon: icon)
                        }
                    } label: {
                        HStack(spacing: 15) {
                            Image(icon.previewName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 70, height: 70)
                                .cornerRadius(8)
                                .shadow(color: .gray.opacity(0.1), radius: 4)
                                .padding(.vertical)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(icon.name)
                                    .font(.system(size: 15, weight: .semibold, design: .default))
                                
                                Text(icon.hex)
                                    .font(.system(size: 12, weight: .semibold, design: .default))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if icon == activeIcon {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("App Icon Gallery")
        .navigationBarTitleDisplayMode(.inline)
    }
   
    @MainActor
    func setIcon(icon: AppIcon) async {
        do {
            try await UIApplication.shared.setAlternateIconName(icon.iconImageName)
            activeIcon = icon
        } catch let err {
            print(err)
        }
    }
}

struct AppIconSelectorView_Preview: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AppIconSelectorView()
                .preferredColorScheme(.dark)
        }
    }
}
