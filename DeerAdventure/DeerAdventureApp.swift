//
//  DeerAdventureApp.swift
//  DeerAdventure
//
//  Created by Vitalii Klimov on 07.02.2026.
//

import SwiftUI
import SwiftData

@main
struct DeerAdventureApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [DayValueEntry.self])
        }
    }
}
