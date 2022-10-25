//
//  CrateApp.swift
//  Crate
//
//  Created by Mike Choi on 10/12/22.
//

import SwiftUI

struct DetailPayload: Identifiable, Hashable {
    let id: UUID
    let folder: Folder
    let detail: PictureEntry?
}

@main
struct CrateApp: App {
    @State var detailPayload: DetailPayload? = nil
    @State var showSettings = false
    @State var zoomFactor: Double = 4
    
    @StateObject var panelDelegate = DetailFloatingPanelDelegate()
    @StateObject var settingsPanelDelegate = SettingsPanelDelegate()
    @StateObject var detailViewModel = ImageDetailViewModel()
    let dataController = DataController.shared
    
    var body: some Scene {
        WindowGroup {
            HomeView(detailPayload: $detailPayload, zoomFactor: $zoomFactor, showSettings: $showSettings)
                .environment(\.managedObjectContext, dataController.container.viewContext)
                .floatingPanel(delegate: panelDelegate) { proxy in
                    ImageDetailView(proxy: proxy, detailPayload: $detailPayload)
                        .environmentObject(detailViewModel)
                }
                .floatingPanel(delegate: settingsPanelDelegate) { proxy in
                    HomeSettingsView(proxy: proxy, showSettings: $showSettings, zoomFactor: $zoomFactor)
                }
                .floatingPanelSurfaceAppearance(.phone)
                .floatingPanelContentMode(.fitToBounds)
                .floatingPanelContentInsetAdjustmentBehavior(.never)
        }
    }
}
