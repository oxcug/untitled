//
//  DataController.swift
//  untitled
//
//  Created by Mike Choi on 10/24/22.
//

import UIKit
import CoreData

final class DataController: ObservableObject {
    static let shared = DataController()
   
    static var preview: DataController = {
        let result = DataController(inMemory: true)
        let viewContext = result.container.viewContext
        
        let entry = PictureEntry(context: viewContext)
        entry.id = UUID()
        entry.name = "sweater"
        entry.date = Date()
        entry.modified = ImageStorage.shared.write(UIImage(named: "modified_4.png"), entryID: entry.id!, isOriginal: false)
        entry.original = ImageStorage.shared.write(UIImage(named: "represent.jpeg"), entryID: entry.id!, isOriginal: true)
        entry.boxes = NSArray()
        
        let folder = PictureFolder(context: viewContext)
        folder.id = UUID()
        folder.name = "Favorites"
        folder.emoji = "🔥"
        folder.entries = NSOrderedSet(array: [entry])
        
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()
    
    let container = NSPersistentContainer(name: "Crate")
    
    init(inMemory: Bool = false) {
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        }
    }
}
