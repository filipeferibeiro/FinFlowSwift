import SwiftUI

public struct MainTabView: View {
    public init() {}

    public var body: some View {
        TabView {
            Tab("Início", systemImage: "house.fill") {
                HomeView()
            }

            Tab("Transações", systemImage: "arrow.up.arrow.down") {
                TransactionsView()
            }

            Tab("Ajustes", systemImage: "gear") {
                SettingsView()
            }
        }
        .tint(Theme.Colors.primary)
    }
}
