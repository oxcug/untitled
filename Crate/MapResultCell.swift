//
//  MapResultCell.swift
//  untitled
//
//  Created by Mike Choi on 12/12/22.
//

import Foundation
import SwiftUI
import MapKit

final class MapResultCellViewModel: ObservableObject {
    func address(for pl: CLPlacemark) -> String {
        return [[pl.thoroughfare, pl.subThoroughfare], [pl.postalCode, pl.locality]]
            .map { (subComponents) -> String in
                // Combine subcomponents with spaces (e.g. 1030 + City),
                subComponents.compactMap { $0 }.joined(separator: " ")
            }
            .filter({ return !$0.isEmpty }) // e.g. no street available
            .joined(separator: ", ") // e.g. "MyStreet 1" + ", " + "1030 City"
    }
    
    func titleSegments(_ title: String?, query: String) -> [(text: String, bold: Bool)] {
        guard let title = title, let range = title.lowercased().range(of: query.lowercased()) else {
            return []
        }
        
        let prefix = title[title.startIndex..<range.lowerBound]
        let middle = title[range.lowerBound..<range.upperBound]
        let suffix = range.upperBound < title.endIndex ? title[range.upperBound..<title.endIndex] : ""
        
        return [
            (String(prefix), false),
            (String(middle), true),
            (String(suffix), false)
        ]
    }
}

extension MKPointOfInterestCategory {
    var color: Color {
        switch self {
            case .airport, .aquarium, .beach, .laundry, .marina:
                return .blue
            case .winery:
                return .purple
            case .atm, .bank, .campground, .park, .nationalPark, .evCharger, .zoo:
                return .green
            case .restaurant, .store, .bakery, .brewery, .cafe, .foodMarket, .nightlife:
                return .orange
            case .library, .school, .hotel, .fitnessCenter, .movieTheater, .gasStation, .fitnessCenter, .amusementPark, .carRental, .stadium, .restroom, .publicTransport, .university, .store, .museum:
                return .gray
            case .fireStation, .police, .postOffice, .gasStation, .pharmacy, .hospital:
                return .red
            default:
                return .orange
        }
    }
    
    var systemIconName: String {
        switch self {
            case .airport:
                return "airplane.departure"
            case .beach:
                return "beach.umbrella.fill"
            case .aquarium, .marina:
                return "fish.fill"
            case .winery, .brewery, .nightlife:
                return "wineglass.fill"
            case .atm, .beach:
                return "dollarsign"
            case .campground, .park, .nationalPark, .zoo:
                return "tree.fill"
            case .restaurant:
                return "fork.knife"
            case .store, .bank, .foodMarket, .store:
                return "basket.fill"
            case .cafe:
                return "cup.and.saucer.fill"
            case .library, .bank, .atm, .school, .university, .museum:
                return "building.columns.fill"
            case .hotel:
                return "building.fill"
            case .fitnessCenter:
                return "dumbbell.fill"
            case .carRental:
                return "car.fill"
            case .publicTransport:
                return "bus.doubledecker.fill"
            case .police, .fireStation:
                return "shield.fill"
            case .postOffice:
                return "mail.fill"
            default:
                return "mappin"
        }
    }
}

struct MapResultCell: View {
    let place: MKMapItem
    let address: String?
    let distanceFromUser: String?
    let titleSegments: [(text: String, bold: Bool)]?
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .center, spacing: 4) {
                ZStack {
                    Image(systemName: place.pointOfInterestCategory?.systemIconName ?? "mappin")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 16, maxHeight: 16)
                        .foregroundColor(place.pointOfInterestCategory?.color ?? .gray)
                    Circle()
                        .foregroundColor((place.pointOfInterestCategory?.color ?? .gray).opacity(0.3))
                        .frame(width: 26, height: 26)
                }
               
                if let distance = distanceFromUser {
                    Text(distance)
                        .font(.system(size: 11, weight: .regular, design: .default))
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 3) {
                if let segments = titleSegments, !segments.isEmpty {
                    Text(segments[0].text)
                        .font(.system(size: 15, weight: .regular, design: .default))
                        .foregroundColor(.secondary) +
                    Text(segments[1].text)
                        .font(.system(size: 15, weight: .regular, design: .default))
                        .foregroundColor(.primary) +
                    Text(segments[2].text)
                        .font(.system(size: 15, weight: .regular, design: .default))
                        .foregroundColor(.secondary)
                } else {
                    if let placeName = place.name {
                        Text(placeName)
                            .font(.system(size: 15, weight: .regular, design: .default))
                            .foregroundColor(.primary)
                    } else {
                        Text("untitled.")
                            .font(.system(size: 15, weight: .regular, design: .default))
                            .foregroundColor(.secondary)
                    }
                }

                if let addr = address, !addr.isEmpty {
                    Text(addr)
                        .font(.system(size: 12, weight: .regular, design: .default))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct MapResultCell_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MapSearchView(query: "soho house")
        }
    }
}
