//
//  MapSearchView.swift
//  untitled
//
//  Created by Mike Choi on 12/11/22.
//

import Combine
import SwiftUI
import MapKit
import FloatingPanel

extension MKMapItem: Identifiable { }

final class MapResultFloatingPanelLayout: FloatingPanelLayout {
    let position: FloatingPanel.FloatingPanelPosition = .bottom
    
    let initialState: FloatingPanel.FloatingPanelState = .full
    
    var anchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] {
        [
            .half: FloatingPanelLayoutAnchor(fractionalInset: 0.5, edge: .bottom, referenceGuide: .safeArea),
            .full: FloatingPanelLayoutAnchor(absoluteInset: 50, edge: .top, referenceGuide: .safeArea),
            .hidden: FloatingPanelLayoutAnchor(absoluteInset: 0, edge: .bottom, referenceGuide: .superview)
        ]
    }
    
    func backdropAlpha(for state: FloatingPanelState) -> CGFloat {
        state == .full ? 1 : 0
    }
}

final class MapModalDelegate: FloatingPanelControllerDelegate, ObservableObject {
    
    @Published var state: FloatingPanelState = .full {
        didSet {
            vc?.surfaceView.grabberHandle.isHidden = (state == .full)
        }
    }
    
    var vc: FloatingPanelController? {
        didSet {
            self.vc?.backdropView.backgroundColor = .systemBackground
        }
    }
    
    func move(to state: FloatingPanelState) {
        vc?.move(to: state, animated: true)
        self.state = state
    }
    
    func floatingPanelWillBeginDragging(_ vc: FloatingPanelController) {
        if vc.state == .full {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    func floatingPanelDidChangeState(_ fpc: FloatingPanelController) {
        state = fpc.state
    }
    
    func floatingPanel(_ fpc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout {
        self.vc = fpc
        return MapResultFloatingPanelLayout()
    }
}

final class MapSearchViewModel: NSObject, ObservableObject {
    
    let locationManager = CLLocationManager()
    var userLocation: CLLocation?
    
    @Published var mapFrame: MKCoordinateRegion = .init(center: .init(latitude: 0, longitude: 0), span: .init(latitudeDelta: 0, longitudeDelta: 0))
    @Published var isFetching = false
    @Published var results: [MKMapItem] = []
    @Published var query: String = ""
    
    lazy var measurementFormatter: MeasurementFormatter = {
        let mf = MeasurementFormatter()
        
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 1
        mf.numberFormatter = nf
        
        mf.unitStyle = .medium
        return mf
    }()
    
    let searchQueue = DispatchQueue(label: "com.mjc.crate.map.search")
    var search: MKLocalSearch?
    var cancellable: AnyCancellable?
    
    override init() {
        super.init()
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        
        cancellable = $query.debounce(for: 0.2, scheduler: RunLoop.main)
            .compactMap { $0 }
            .sink { [weak self] in
                self?.search(query: $0)
            }
    }
    
    func search(query: String) {
        search?.cancel()
        
        if query.isEmpty {
            results = []
            return
        }
        
        isFetching = true
        
        searchQueue.async { [weak self] in
            guard let self = self else { return }
            
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            self.search = MKLocalSearch(request: request)
            self.search?.start { [weak self] res, err in
                withAnimation {
                    self?.isFetching = false
                    self?.results = res?.mapItems ?? []
                    self?.setZoom(coordinates: self?.results.map(\.placemark.coordinate) ?? [])
                }
            }
        }
    }
    
    func setZoom(coordinates: [CLLocationCoordinate2D?]) {
        if coordinates.isEmpty {
            return
        }
        
        let union = coordinates
            .compactMap { $0 }
            .reduce(MKMapRect.null, { acc, cur in
                acc.union(.init(origin: .init(cur), size: .init(width: 0, height: 0)))
            })
        
        var newRegion = MKCoordinateRegion(union)
        
        if coordinates.count == 1 {
            let delta = 0.007
            newRegion.span = .init(latitudeDelta: delta, longitudeDelta: delta)
        } else {
            newRegion.span.latitudeDelta *= 1.4
            newRegion.span.longitudeDelta *= 1.4
        }
        
        mapFrame = newRegion
    }
    
    func distanceFromUser(point: MKMapItem) -> String? {
        guard let userLocation = userLocation, let dest = point.placemark.location else {
            return nil
        }
        
        let distanceInMeters = userLocation.distance(from: dest)
        return measurementFormatter.string(for: Measurement(value: distanceInMeters, unit: UnitLength.meters))
    }
}

extension MapSearchViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            return
        }
        
        userLocation = location
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.requestLocation()
        }
    }
}

struct MapResultList: View {
    var didTapPlace: (MKMapItem) -> ()
    @EnvironmentObject var viewModel: MapSearchViewModel
    @EnvironmentObject var resultViewModel: MapResultCellViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.results) { place in
                Button {
                    didTapPlace(place)
                } label: {
                    MapResultCell(place: place,
                                  address: resultViewModel.address(for: place.placemark),
                                  distanceFromUser: viewModel.distanceFromUser(point: place),
                                  titleSegments: resultViewModel.titleSegments(place.name, query: viewModel.query))
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.plain)
    }
}

// MARK: -

struct MapContentView: View {
    let query: String
    
    @FocusState var searchFocused: Bool
    @EnvironmentObject var viewModel: MapSearchViewModel
    @EnvironmentObject var resultViewModel: MapResultCellViewModel
    @EnvironmentObject var panelDelegate: MapModalDelegate
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                Map(coordinateRegion: $viewModel.mapFrame, showsUserLocation: true, annotationItems: viewModel.results) { annotation in
                    MapMarker(coordinate: annotation.placemark.coordinate, tint: annotation.pointOfInterestCategory?.color ?? .red)
                }
                .edgesIgnoringSafeArea(.top)
                
                    
                Button {
                    panelDelegate.move(to: .half)
                } label: {
                    Text("show results")
                        .font(.system(size: 15, weight: .semibold, design: .default))
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding()
                .background(Color(uiColor: .systemBackground))
                .opacity(panelDelegate.state == .hidden ? 1 : 0)
            }
            
            if searchFocused {
                MapResultList { mapItem in
                    searchFocused = false
                }
                .environmentObject(viewModel)
                .environmentObject(resultViewModel)
            }
        }
    }
}

struct MapSearchView: View {
    let query: String
    @FocusState var searchFocused: Bool
    
    @StateObject var panelDelegate = MapModalDelegate()
    @StateObject var viewModel = MapSearchViewModel()
    @StateObject var resultViewModel = MapResultCellViewModel()
    
    var body: some View {
        MapContentView(query: query, searchFocused: _searchFocused)
            .floatingPanel(delegate: panelDelegate) { proxy in
                ModalMapResultList(proxy: proxy, didTapPlace: { place in
                })
                .environmentObject(viewModel)
                .environmentObject(resultViewModel)
            }
            .environmentObject(viewModel)
            .environmentObject(resultViewModel)
            .environmentObject(panelDelegate)
            .floatingPanelSurfaceAppearance(.phone)
            .floatingPanelContentMode(.fitToBounds)
            .floatingPanelContentInsetAdjustmentBehavior(.never)
            .onReceive(Publishers.keyboardWillBeVisible) { visible in
                panelDelegate.vc?.move(to: visible ? .full : .half, animated: true)
            }
            .overlay(
                searchBar
                    .frame(maxHeight: .infinity, alignment: .top)
            )
            .onAppear {
                searchFocused = true
            }
            .task {
                viewModel.query = query
            }
    }
    
    var searchBar: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "arrow.left")
                .font(.system(size: 19, weight: .semibold, design: .default))
                .foregroundColor(.primary)
            
            TextField("search here", text: $viewModel.query)
                .focused($searchFocused)
                .onSubmit {
                    searchFocused = false
                }
            
            Button {
                viewModel.query = ""
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .opacity(viewModel.query.count > 1 ? 1 : 0)
        }
        .padding(12)
        .background(
            Capsule()
                .stroke(Color(uiColor: .secondarySystemFill), lineWidth: 1)
                .background(Capsule().foregroundColor(Color(uiColor: .tertiarySystemBackground)))
        )
        .shadow(color: .black.opacity(panelDelegate.state == .full ? 0 : 0.2), radius: 10, x: 5, y: 5)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .padding(.top, 2)
    }
}

struct MapSearchView_Previews: PreviewProvider {
    static var previews: some View {
        MapSearchView(query: "soho house")
            .previewDevice(PreviewDevice(rawValue: "iPhone 14 Pro Max"))
    }
}
