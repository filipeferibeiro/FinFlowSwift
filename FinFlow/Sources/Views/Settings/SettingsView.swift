import SwiftUI
import SwiftData

public struct SettingsView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @Environment(\.modelContext) private var modelContext
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            BaseView {
                Form {
                    Section("Gerenciar") {
                        NavigationLink("Adicionar Nova Conta") {
                            AddAccountView()
                        }
                    }
                    .listRowBackground(Theme.Colors.surfaceSolid)
                    
                    Section("Área de Testes (Temporário)") {
                        Button("Voltar para o Onboarding") {
                            withAnimation {
                                hasCompletedOnboarding = false
                            }
                        }
                        .foregroundStyle(Theme.Colors.primary)
                        
                        Button("Resetar App (Apagar Tudo)") {
                            wipeData()
                        }
                        .foregroundStyle(Theme.Colors.error)
                    }
                    .listRowBackground(Theme.Colors.surfaceSolid)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Ajustes")
            .scrollEdgeEffectStyle(.soft, for: .top)
        }
    }
    
    private func wipeData() {
        do {
            try modelContext.delete(model: Account.self)
            try modelContext.delete(model: Transaction.self)
            withAnimation {
                hasCompletedOnboarding = false
            }
        } catch {
            print("Erro ao limpar dados SwiftData: \(error.localizedDescription)")
        }
    }
}
