//
//  SettingsView.swift
//  untitled
//
//  Created by Mike Choi on 11/10/22.
//

import SwiftUI
import Instabug

struct AlertPayload: Identifiable, Equatable {
    let id = UUID()
    let emoji: String
    let message: String
}

enum SettingRow: Int, Identifiable, CaseIterable {
    case appIcon, theme
    
    case about, feedback, bugReport, contact, invite, rate, tutorial
    
    var id: String {
        description
    }
    
    var description: String {
        switch self {
            case .theme:
                return "Theme"
            case .appIcon:
                return "App Icon"
            case .contact:
                return "Contact us"
            case .about:
                return "About"
            case .invite:
                return "Invite your friends"
            case .feedback:
                return "Feedback"
            case .bugReport:
                return "Bug report"
            case .rate:
                return "Rate untitled."
            case .tutorial:
                return "Tutorial"
        }
    }
    
    var iconName: String {
        switch self {
            case .theme:
                return "moon.fill"
            case .appIcon:
                return "app.fill"
            case .contact:
                return "hand.wave.fill"
            case .about:
                return "at"
            case .invite:
                return "envelope.fill"
            case .feedback:
                return "lightbulb.fill"
            case .bugReport:
                return "ant.fill"
            case .rate:
                return "heart.fill"
            case .tutorial:
                return "eyeglasses"
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
    @State var showURL: String?
    @State var alertPayload: AlertPayload?
    
    @AppStorage("did.show.bug.report.tutorial") var didShowBugReportTutorial = false
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
                    ForEach([SettingRow.bugReport, SettingRow.feedback, SettingRow.contact]) { row in
                        Button {
                            if row == .contact {
                                showBugReportUI(action: "send us a message")
                            } else {
                                showBugReportUI(action: "quickly submit a \(row == .feedback ? "feedback" : "bug report")")
                            }
                        } label: {
                            SettingsCell(row: row)
                        }
                    }
                }
                
                Section {
                    ForEach([SettingRow.tutorial, SettingRow.about,SettingRow.invite, SettingRow.rate]) { row in
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
                    case .tutorial:
                        TutorialView()
                    default:
                        VStack(spacing: 20) {
                            Text("🔜")
                            Text("tbd")
                        }
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
        .sheet(item: $showURL) { url in
            SafariView(url: URL(string: url)!)
        }
        .presentAlert(alertPayload: $alertPayload)
    }
    
    func showBugReportUI(action: String) {
        if !didShowBugReportTutorial {
            alertPayload = .init(emoji: "💡", message: "Shake your device to \(action)")
            didShowBugReportTutorial = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                Instabug.show()
            }
        } else {
            Instabug.show()
        }
    }
}

struct SettingsView_Preview: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SettingsView()
                .preferredColorScheme(.light)
        }
    }
}
