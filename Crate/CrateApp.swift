//
//  CrateApp.swift
//  untitled
//
//  Created by Mike Choi on 10/12/22.
//

import Combine
import SwiftUI

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
    
    var body: some Scene {
        WindowGroup {
            HomeView(showSettings: $showSettings, showVisualSettings: $showVisualSettings)
                .preferredColorScheme(.dark)
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
