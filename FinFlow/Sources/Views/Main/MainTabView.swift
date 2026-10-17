import SwiftUI

public struct MainTabView: View {
    public init() {}

    public var body: some View {
        TabView {
            Tab("Visão Geral", systemImage: "chart.pie.fill") {
                HomeView()
            }

            Tab("Extrato", systemImage: "list.bullet.rectangle.portrait.fill") {
                TransactionsView()
            }

            Tab("Ajustes", systemImage: "gearshape.fill") {
                SettingsView()
            }
        }
        .tint(Theme.Colors.primary)
    }
}
