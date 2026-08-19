//
//  FinFlowApp.swift
//  FinFlow
//
//  Created by Filipe Fernandes on 16/08/26.
//

import SwiftUI
import SwiftData

@main
struct FinFlowApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Account.self, Transaction.self])
    }
}
