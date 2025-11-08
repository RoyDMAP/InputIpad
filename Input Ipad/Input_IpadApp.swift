//
//  Input_IpadApp.swift
//  Input Ipad
//
//  Created by Roy Dimapilis on 11/06/25.


import SwiftUI

@main
struct Input_IpadApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            DrawingGalleryView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
