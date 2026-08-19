import SwiftUI

public struct MainTabView: View {
    public init() {}
    
    public var body: some View {
        // Modern iOS/iPadOS tab view handling
        TabView {
            HomeView()
                .tabItem {
                    Label("Início", systemImage: "house.fill")
                }
            
            TransactionsView()
                .tabItem {
                    Label("Transações", systemImage: "arrow.up.arrow.down")
                }
            
            SettingsView()
                .tabItem {
                    Label("Ajustes", systemImage: "gear")
                }
        }
        .tint(Theme.Colors.primary) // Make active tab icons match brand color
    }
}
