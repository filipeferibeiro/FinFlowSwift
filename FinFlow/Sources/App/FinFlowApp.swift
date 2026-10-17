import SwiftUI
import SwiftData

@main
struct FinFlowApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Account.self, Transaction.self, CreditCard.self])
    }
}
