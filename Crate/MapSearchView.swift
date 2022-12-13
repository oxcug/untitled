//
//  MapSearchView.swift
//  untitled
//
//  Created by Mike Choi on 12/11/22.
//

import Combine
import SwiftUI
import MapKit
import BottomSheet

extension MKMapItem: Identifiable { }

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
                    self?.setZoom(coordinates: self?.results.map(\.placemark.coordinate) ?? [], isUserLocation: false)
                }
            }
        }
    }
    
    func setZoom(coordinates: [CLLocationCoordinate2D?], isUserLocation: Bool) {
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
            let delta = isUserLocation ? 0.4 : 0.007
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
                    MapResultCell(place: place)
                        .environmentObject(viewModel)
                        .environmentObject(resultViewModel)
                        .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.plain)
    }
}

// MARK: -

struct MapSearchView: View {
    let query: String
    
    @State var userHitSearch = false
    @StateObject var viewModel = MapSearchViewModel()
    @StateObject var resultViewModel = MapResultCellViewModel()
    @FocusState var searchFocused: Bool
    
    @State var bottomSheetPosition: BottomSheetPosition = .relative(0.4)
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    if !searchFocused {
                        Map(coordinateRegion: $viewModel.mapFrame, showsUserLocation: true, annotationItems: viewModel.results) { annotation in
                            MapMarker(coordinate: annotation.placemark.coordinate, tint: annotation.pointOfInterestCategory?.color ?? .red)
                        }
                    }
                    
                    VStack {
                        searchBar
                        
                        if !searchFocused {
                            Spacer()
                            
                            Button {
                                bottomSheetPosition = .relative(0.4)
                            } label: {
                                Text("show results")
                                    .font(.system(size: 15, weight: .semibold, design: .default))
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding()
                            .background(Color(uiColor: .systemBackground))
                        }
                    }
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
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.query = query
        }
        .bottomSheet(bottomSheetPosition: $bottomSheetPosition, switchablePositions: [
            .relative(0.5),
            .hidden
        ], content: {
            MapResultList { place in
                searchFocused = false
                userHitSearch = true
            }
            .environmentObject(viewModel)
            .environmentObject(resultViewModel)
        })
        .customBackground(Color(uiColor: .systemBackground).cornerRadius(22))
        .customAnimation(.spring(
            response: 0.4,
            dampingFraction: 0.9,
            blendDuration: 1
        ))
        .enableSwipeToDismiss()
        .onChange(of: bottomSheetPosition) { bottomSheetPosition in
            print(bottomSheetPosition)
        }
        .onChange(of: searchFocused) { searchFocused in
            bottomSheetPosition = searchFocused ? .hidden : .relative(0.5)
        }
    }
    
    var searchBar: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("search here", text: $viewModel.query)
                .focused($searchFocused)
                .onSubmit {
                    userHitSearch = true
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
        .shadow(color: .black.opacity(searchFocused ? 0 : 0.2), radius: 10, x: 5, y: 5)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .padding(.top, 2)
    }
}

struct MapSearchView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MapSearchView(query: "soho house")
        }
    }
}
