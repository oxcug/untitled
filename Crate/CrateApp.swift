//
//  CrateApp.swift
//  Crate
//
//  Created by Mike Choi on 10/12/22.
//

import SwiftUI

@main
struct CrateApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
