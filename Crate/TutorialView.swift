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
                return "https://s3.us-east-2.amazonaws.com/com.mjc.juice/untitled-videos/share-sheet.mov"
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
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 40) {
                LineSegmentedView(color: .blue,
                                  selectedIndex: $selectedIndex,
                                  titles: Method.allCases.map { $0.description })
                
                ZStack(alignment: .center) {
                    PlayerView(player: $player)
                        .onAppear() {
                            player.playImmediately(atRate: 0.6)
                        }
                    
                    if !viewModel.isVideoPlaying {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                }
                Spacer()
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
        .onChange(of: selectedIndex) { idx in
            guard let method = Method(rawValue: idx) else {
                return
            }
            
            let item = AVPlayerItem(url: URL(string: method.url)!)
            self.player.replaceCurrentItem(with: item)
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
