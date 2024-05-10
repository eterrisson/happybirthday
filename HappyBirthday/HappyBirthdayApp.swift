//
//  HappyBirthdayApp.swift
//  HappyBirthday
//
//  Created by Eric Terrisson on 09/05/2024.
//

import SwiftUI

@main
struct HappyBirthdayApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
