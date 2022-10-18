//
//  CrateApp.swift
//  Crate
//
//  Created by Mike Choi on 10/12/22.
//

import SwiftUI

struct DetailPayload: Identifiable, Hashable {
    let id: UUID
    let folderName: String
    let detail: Entry?
}

@main
struct CrateApp: App {
    @StateObject var panelDelegate = DetailFloatingPanelDelegate()
    @State var folderName = ""
    @State var detailPayload: DetailPayload? = nil
    @StateObject var detailViewModel = ImageDetailViewModel()
    
    var body: some Scene {
        WindowGroup {
            HomeView(detailPayload: $detailPayload)
                .floatingPanel(delegate: panelDelegate) { proxy in
                    ImageDetailView(proxy: proxy, detailPayload: $detailPayload)
                        .environmentObject(detailViewModel)
                }
                .floatingPanelSurfaceAppearance(.phone)
                .floatingPanelContentMode(.fitToBounds)
                .floatingPanelContentInsetAdjustmentBehavior(.never)
        }
    }
}
