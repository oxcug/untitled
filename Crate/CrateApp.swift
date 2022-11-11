//
//  CrateApp.swift
//  untitled
//
//  Created by Mike Choi on 10/12/22.
//

import Combine
import SwiftUI
import Instabug

struct DetailPayload: Identifiable, Hashable {
    let id: UUID
    let folder: Folder?
    let detail: PictureEntry?
    
    static let dummy = DetailPayload(id: UUID(), folder: nil, detail: nil)
}

@main
struct CrateApp: App {
    @State var detailPayload: DetailPayload = .dummy
    @State var showVisualSettings = false
    @State var showSettings = false
    
    @AppStorage("show.labels") var showLabels = true
    @AppStorage("zoom.factor") var zoomFactor: Double = 4.0
    @AppStorage("theme") var theme: Theme = .lightsOff
    
    init() {
        Instabug.start(withToken: "2b7de71991b983519f193a88b22ce9e1", invocationEvents: [.shake, .screenshot])
    }
    
    var body: some Scene {
        WindowGroup {
            HomeView(showSettings: $showSettings, showVisualSettings: $showVisualSettings)
                .preferredColorScheme(theme.colorScheme)
                .environment(\.managedObjectContext, DataController.shared.container.viewContext)
                .presentModal(isPresented: $showVisualSettings, height: 200) {
                    HomeSettingsView(showSettings: $showSettings)
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView()
                }
        }
    }
}
