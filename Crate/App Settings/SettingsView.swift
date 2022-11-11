//
//  SettingsView.swift
//  untitled
//
//  Created by Mike Choi on 11/10/22.
//

import SwiftUI

enum SettingRow: Int, Identifiable, CaseIterable {
    case appIcon, theme
    
    case about, help, invite
    
    var id: String {
        description
    }
    
    var description: String {
        switch self {
            case .theme:
                return "Theme"
            case .appIcon:
                return "App Icon"
            case .help:
                return "Help"
            case .about:
                return "About"
            case .invite:
                return "Invite your friends"
        }
    }
    
    var iconName: String {
        switch self {
            case .theme:
                return "moon.fill"
            case .appIcon:
                return "app.fill"
            case .help:
                return "questionmark"
            case .about:
                return "at"
            case .invite:
                return "envelope.fill"
        }
    }
}

struct SettingsCell: View {
    let row: SettingRow
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: row.iconName)
                .frame(width: 30)
            Text(row.description)
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("").frame(height: 0)) {
                    ForEach([SettingRow.appIcon, SettingRow.theme]) { row in
                        NavigationLink(value: row) {
                            SettingsCell(row: row)
                        }
                    }
                }
                
                Section {
                    ForEach([SettingRow.about, SettingRow.help, SettingRow.invite]) { row in
                        NavigationLink(value: row) {
                            SettingsCell(row: row)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: SettingRow.self) { row in
                switch row {
                    case .appIcon:
                        AppIconSelectorView()
                    case .theme:
                        ThemeSelectorView()
                    case .about:
                        AboutView()
                    default:
                        Text("ASDF")
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("done") {
                        dismiss()
                    }
                    .tint(.bodyText)
                }
                
                ToolbarItem(placement: .principal) {
                    Text("settings.")
                        .font(.system(size: 17, weight: .semibold, design: .default))
                }
            }
        }
        .tint(.bodyText)
    }
}

struct SettingsView_Preview: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SettingsView()
        }
    }
}
