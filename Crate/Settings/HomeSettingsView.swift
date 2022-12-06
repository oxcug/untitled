//
//  HomeSettingsView.swift
//  untitled
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
    @AppStorage("active.icon") var activeIcon: AppIcon = .untitled
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Visuals")
                .font(.system(size: 15, weight: .semibold, design: .default))
                .foregroundColor(Color.bodyText.opacity(0.8))
            
            Separator()
                .opacity(0.5)
            
            HStack(spacing: 15) {
                Text("Zoom")
                    .modifier(SemiBoldBodyTextModifier())
               
                Spacer()
                
                Slider(value: $zoomFactor, in: 0.8...6.0, step: 0.1)
                    .tint(activeIcon.color)
            }
            
            HStack(alignment: .center, spacing: 15) {
                Text("Text")
                    .modifier(SemiBoldBodyTextModifier())
                
                Spacer()
                
                Toggle(isOn: $showLabels) { }
                    .tint(activeIcon.color)
            }
            
            Spacer()
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
        HomeView(detailPayload: .dummy, showSettings: $showSettings, showVisualSettings: .constant(false))
            .environment(\.managedObjectContext, DataController.preview.container.viewContext)
            .presentModal(isPresented: $showSettings, height: 200) {
                HomeSettingsView(showSettings: $showSettings)
            }
    }
}
