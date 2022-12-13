//
//  ModalMapResultList.swift
//  untitled
//
//  Created by Mike Choi on 12/13/22.
//

import Combine
import MapKit
import SwiftUI

struct ModalMapResultListRepresentable: UIViewControllerRepresentable {
    var onScrollViewCreated: (_ scrollView: UIScrollView) -> Void
    @EnvironmentObject var viewModel: MapSearchViewModel
    @EnvironmentObject var cellViewModel: MapResultCellViewModel
    
    func makeUIViewController(context: Context) -> MapResultsTableViewController {
        let tableVC = MapResultsTableViewController()
        tableVC.resultsPublisher =  viewModel.$results.eraseToAnyPublisher()
        tableVC.viewModel = viewModel
        tableVC.cellViewModel = cellViewModel
        onScrollViewCreated(tableVC.tableView)
        return tableVC
    }
    
    func updateUIViewController(_ uiViewController: MapResultsTableViewController, context: Context) {
//        uiViewController.date = self.date
    }
}

struct MapResultItem: Hashable {
    let location: MKMapItem
}

final class MapResultsTableViewController: UITableViewController {
    private lazy var dataSource: UITableViewDiffableDataSource<String, MapResultItem> = {
        UITableViewDiffableDataSource<String , MapResultItem>(tableView: tableView) { [weak self] tableView, _, item in
            self?.tableView(tableView, cellForTableViewItem: item)
        }
    }()
  
    var viewModel: MapSearchViewModel!
    var cellViewModel: MapResultCellViewModel!
    var resultsPublisher: AnyPublisher<[MKMapItem], Never>?
    var resultsStream: AnyCancellable?
    var didTapLocation: (() -> ())?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorStyle = .none
        tableView.register(HostingCell<MapResultCell>.self, forCellReuseIdentifier: "results.cell")
        tableView.dataSource = dataSource
       
        resultsStream = resultsPublisher?.receive(on: RunLoop.main).sink { [weak self] in
            self?.applyDataSource(locations: $0)
        }
    }
    
    private func applyDataSource(locations: [MKMapItem]) {
        var snapshot = NSDiffableDataSourceSnapshot<String, MapResultItem>()
        
        snapshot.appendSections(["main"])
        snapshot.appendItems(locations.map { MapResultItem(location: $0) }, toSection: "main")
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    private func tableView(_ tableView: UITableView, cellForTableViewItem item: MapResultItem) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "results.cell") as? HostingCell<MapResultCell> else {
            return UITableViewCell()
        }
        setupCell(cell, location: item)
        return cell
    }
    
    func setupCell(_ cell: HostingCell<MapResultCell>, location: MapResultItem) {
        let location = location.location
        
        cell.selectionStyle = .none
        cell.set(rootView: MapResultCell(place: location,
                                         address: cellViewModel.address(for: location.placemark),
                                         distanceFromUser: viewModel.distanceFromUser(point: location),
                                         titleSegments: cellViewModel.titleSegments(location.placemark.name, query: viewModel.query)),
                 parentController: self)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = dataSource.itemIdentifier(for: indexPath)
    }
}


struct ModalMapResultList: View {
    var proxy: FloatingPanelProxy
    var didTapPlace: (MKMapItem) -> ()
    @EnvironmentObject var viewModel: MapSearchViewModel
    @EnvironmentObject var resultViewModel: MapResultCellViewModel
    
    var body: some View {
        VStack {
            ModalMapResultListRepresentable(onScrollViewCreated: proxy.track(scrollView:))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 22)
        .padding(.horizontal)
        .ignoresSafeArea()
    }
}

struct ModalMapResultList_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MapSearchView(query: "soho house")
        }
    }
}
