//
//  HomeSettingsView.swift
//  Crate
//
//  Created by Mike Choi on 11/6/22.
//

import Foundation
import SwiftUI

struct HomeSettingsView: View {
    @Binding var showSettings: Bool
    
    @Environment(\.dismiss) var dismiss
    @AppStorage("show.labels") var showLabels = true
    @AppStorage("zoom.factor") var zoomFactor: Double = 4.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Settings")
                .font(.system(size: 24, weight: .semibold, design: .default))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 15) {
                Text("Zoom")
                    .font(.system(size: 15, weight: .semibold, design: .default))
                    .foregroundColor(.white)
                
                HStack(spacing: 12) {
                    Image(systemName: "minus.magnifyingglass")
                        .font(.system(size: 20, weight: .light, design: .default))
                        .foregroundColor(.white)
                    
                    Slider(value: $zoomFactor, in: 1...10, step: 0.25)
                        .tint(.white)
                    
                    Image(systemName: "plus.magnifyingglass")
                        .font(.system(size: 20, weight: .light, design: .default))
                        .foregroundColor(.white)
                }
            }
            
            HStack(alignment: .center, spacing: 15) {
                Text("Text")
                    .font(.system(size: 15, weight: .semibold, design: .default))
                    .foregroundColor(.white)
                
                Spacer()
                
                Toggle(isOn: $showLabels) { }
                    .tint(.white.opacity(0.4))
            }
        }
        .padding()
        .onChange(of: showSettings) { _ in
            dismiss()
        }
    }
}

struct HomeSettingsView_Previews: PreviewProvider {
    @StateObject static var detailViewModel = PictureEntryDetailViewModel()
    @State static var showSettings = true

    static var previews: some View {
        HomeView(detailPayload: .dummy, showSettings: $showSettings)
            .environment(\.managedObjectContext, DataController.preview.container.viewContext)
            .presentModal(isPresented: $showSettings) {
                HomeSettingsView(showSettings: $showSettings)
            }
    }
}
