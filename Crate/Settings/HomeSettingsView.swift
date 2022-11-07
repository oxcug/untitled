//
//  HomeSettingsView.swift
//  Crate
//
//  Created by Mike Choi on 11/6/22.
//

import Foundation
import SwiftUI

struct HomeSettingsView: View {
    let proxy: FloatingPanelProxy
    @Binding var showSettings: Bool
    @Binding var showLabels: Bool
    @Binding var zoomFactor: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Settings")
                .font(.system(size: 24, weight: .semibold, design: .default))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 15) {
                Text("Zoom")
                    .font(.system(size: 15, weight: .semibold, design: .default))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    Image(systemName: "minus.magnifyingglass")
                        .font(.system(size: 20, weight: .light, design: .default))
                    
                    Slider(value: $zoomFactor, in: 1...15, step: 1)
                        .tint(.white)
                    
                    Image(systemName: "plus.magnifyingglass")
                        .font(.system(size: 20, weight: .light, design: .default))
                }
            }
            
            HStack(alignment: .center, spacing: 15) {
                Text("Text")
                    .font(.system(size: 15, weight: .semibold, design: .default))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Toggle(isOn: $showLabels) { }
                    .tint(.white.opacity(0.4))
            }
        }
        .padding()
        .onChange(of: showSettings) { _ in
            proxy.move(to: .full, animated: true)
        }
    }
}

struct HomeSettingsView_Previews: PreviewProvider {
    @StateObject static var panelDelegate = DemoFloatingPanelDelegate()
    @StateObject static var detailViewModel = PictureEntryDetailViewModel()
    @State static var showSettings = true
    @State static var showLabels = true
    @State static var zoomFactor = 1.0

    static var previews: some View {
        HomeView(detailPayload: .dummy, zoomFactor: $zoomFactor, showSettings: $showSettings, showLabels: $showLabels)
            .environment(\.managedObjectContext, DataController.preview.container.viewContext)
            .floatingPanel(delegate: panelDelegate) { proxy in
                HomeSettingsView(proxy: proxy, showSettings: $showSettings, showLabels: $showLabels, zoomFactor: $zoomFactor)
            }
            .floatingPanelSurfaceAppearance(.phone)
            .floatingPanelContentMode(.fitToBounds)
            .floatingPanelContentInsetAdjustmentBehavior(.never)
    }
}
