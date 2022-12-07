//
//  TutorialView.swift
//  untitled
//
//  Created by Mike Choi on 12/6/22.
//

import Combine
import SwiftUI
import AVKit

enum Method: Int, CaseIterable {
    case share, add
    
    var description: String {
        switch self {
            case .share:
                return "share from outside"
            case .add:
                return "in-app"
        }
    }
    
    var url: String {
        switch self {
            case .share:
                return "https://s3.us-east-2.amazonaws.com/com.mjc.juice/untitled-videos/share-sheet.mov"
            case .add:
                return "https://s3.us-east-2.amazonaws.com/com.mjc.juice/untitled-videos/in-app.mov"
        }
    }
}

final class TutorialViewModel: NSObject, ObservableObject {
    @Published var isVideoPlaying = false
    var cancellable: AnyCancellable?
    
    func subscribeToState(of player: AVPlayer) {
        player.addObserver(self, forKeyPath: "timeControlStatus", options: [.old, .new], context: nil)
    }
    
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath == "timeControlStatus",
              let change = change,
              let newValue = change[NSKeyValueChangeKey.newKey] as? Int else {
            return
        }
        
        let newStatus = AVPlayer.TimeControlStatus(rawValue: newValue)
        
        DispatchQueue.main.async { [weak self] in
            if newStatus == .playing || newStatus == .paused {
                self?.isVideoPlaying = true
            } else {
                self?.isVideoPlaying = false
            }
        }
    }
}

struct TutorialView: View {
    @State var selectedIndex = 0
    @State var player = AVPlayer(url: URL(string: "https://s3.us-east-2.amazonaws.com/com.mjc.juice/untitled-videos/share-sheet.mov")!)
    @StateObject var viewModel = TutorialViewModel()
    @AppStorage("active.icon") var activeIcon: AppIcon = .untitled
    @Environment(\.dismiss) var dismiss
    
    let feedback = UIImpactFeedbackGenerator(style: .heavy)
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 40) {
                LineSegmentedView(color: activeIcon.color,
                                  selectedIndex: $selectedIndex,
                                  titles: Method.allCases.map { $0.description })
                
                ZStack(alignment: .center) {
                    PlayerView(player: $player)

                    if !viewModel.isVideoPlaying {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                }
                
                Button {
                    feedback.impactOccurred()
                    dismiss()
                } label: {
                    Text("understood")
                        .font(.system(size: 15, weight: .semibold, design: .default))
                        .foregroundColor(Color(uiColor: .systemBackground))
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .foregroundColor(activeIcon.color)
                        )
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("how to...")
                    .font(.system(size: 15, weight: .semibold, design: .default))
            }
        }
        .task {
            viewModel.subscribeToState(of: player)
        }
        .onAppear {
            player.playImmediately(atRate: 0.7)
            loop()
        }
        .onChange(of: selectedIndex) { idx in
            guard let method = Method(rawValue: idx),
                  let cur = player.currentItem else {
                return
            }
            
            NotificationCenter.default.removeObserver(cur, name: .AVPlayerItemDidPlayToEndTime, object: nil)
            
            let item = AVPlayerItem(url: URL(string: method.url)!)
            player.replaceCurrentItem(with: item)
            loop()
        }
    }
    
    func loop() {
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
            player.seek(to: CMTime.zero)
            player.play()
        }
    }
}


struct TutorialView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            TutorialView()
        }
    }
}
