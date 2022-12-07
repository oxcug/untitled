//
//  OnboardingView.swift
//  Crate
//
//  Created by Mike Choi on 12/6/22.
//

import SwiftUI

struct TutorialRow: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let imageName: String
    let isComingSoon: Bool
    
    static let all: [TutorialRow] = [
        .init(title: "Person isolation", description: "Extract and isolate people in photos", imageName: "person.fill.viewfinder", isComingSoon: false),
        .init(title: "Folders", description: "Finally organize your chaotic collection of screenshots", imageName: "folder.fill", isComingSoon: true),
        .init(title: "Location detection", description: "Automatic location name detection in a photo", imageName: "fork.knife", isComingSoon: true)
    ]
}

struct OnboardingView: View {
    let feedback = UIImpactFeedbackGenerator(style: .heavy)
    
    @State var barWidth: CGFloat = .zero
    @AppStorage("is.new.user") var isNewUser = true
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack(alignment: .bottom) {
            List {
                ZStack(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Welcome to")
                            .font(.system(size: 26, weight: .bold, design: .default))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(.secondary)

                        Text("untitled.")
                            .font(.system(size: 48, weight: .bold, design: .default))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Rectangle()
                        .frame(height: 7)
                        .frame(maxWidth: barWidth)
                        .foregroundColor(Color(uiColor: .label))
                        .offset(y: 5)
                        .animation(.linear(duration: 1.8).delay(0.5), value: barWidth)
                }
                .padding(.horizontal)
                .padding(.vertical, 50)
                .listRowSeparator(.hidden)
                .drawingGroup()
                .onAppear {
                    withAnimation {
                        barWidth = .infinity
                    }
                }
                
                ForEach(TutorialRow.all) { row in
                    HStack(spacing: 18) {
                        Image(systemName: row.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .symbolRenderingMode(.hierarchical)
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text(row.title)
                                .font(.system(size: 15, weight: .semibold, design: .default))
                            
                            Text(row.description)
                                .font(.system(size: 15, weight: .regular, design: .default))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            
            footer
        }
    }
    
    var footer: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Image(systemName: "lock.iphone")
                    .font(.system(size: 40, weight: .regular, design: .default))
                    .foregroundStyle(Color(uiColor: .label))
                    .symbolRenderingMode(.hierarchical)
                
                Text("Everything you save here is locally stored and never leaves your device. No personal and or device data is collected. Happy saving :)")
                    .multilineTextAlignment(.center)
                    .font(.system(size: 12, weight: .regular, design: .default))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            
            Button {
                feedback.impactOccurred()
                dismiss()
                isNewUser = false
            } label: {
                Text("Continue")
                    .font(.system(size: 16, weight: .semibold, design: .default))
                    .foregroundColor(Color(uiColor: .systemBackground))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundColor(Color(uiColor: .label))
                    )
            }
            .padding()
        }
        .background(Color(uiColor: .secondarySystemBackground))
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
