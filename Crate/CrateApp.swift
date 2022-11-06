//
//  CrateApp.swift
//  Crate
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
    @State var showSettings = false
    @State var showLabels = false
    @State var zoomFactor: Double = 4
    
    @StateObject var settingsPanelDelegate = SettingsPanelDelegate()
    let dataController = DataController.shared
    
    var body: some Scene {
        WindowGroup {
            HomeView(detailPayload: detailPayload, zoomFactor: $zoomFactor, showSettings: $showSettings, showLabels: $showLabels)
                .environment(\.managedObjectContext, dataController.container.viewContext)
                .floatingPanel(delegate: settingsPanelDelegate) { proxy in
                    HomeSettingsView(proxy: proxy, showSettings: $showSettings, showLabels: $showLabels, zoomFactor: $zoomFactor)
                }
                .floatingPanelSurfaceAppearance(.phone)
                .floatingPanelContentMode(.fitToBounds)
                .floatingPanelContentInsetAdjustmentBehavior(.never)
        }
    }
}
