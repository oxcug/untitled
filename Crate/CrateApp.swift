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
    
    @StateObject var panelDelegate = DetailFloatingPanelDelegate()
    @StateObject var detailViewModel = ImageDetailViewModel()
    let dataController = DataController.preview
    
    var body: some Scene {
        WindowGroup {
            HomeView(detailPayload: $detailPayload)
                .environment(\.managedObjectContext, dataController.container.viewContext)
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
