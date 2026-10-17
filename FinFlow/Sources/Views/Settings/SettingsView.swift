import SwiftUI
import SwiftData

public struct SettingsView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("userName") private var userName: String = "Usuário"
    @Environment(\.modelContext) private var modelContext

    @State private var showingWipeConfirmation = false
    @State private var errorMessage: String?
    @State private var showingErrorAlert = false

    public init() {}

    public var body: some View {
        NavigationStack {
            BaseView {
                Form {
                    Section("Perfil") {
                        LabeledContent("Seu Nome") {
                            TextField("Ex: Filipe", text: $userName)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    .listRowBackground(Theme.Colors.surfaceSolid)

                    Section("Gerenciar") {
                        NavigationLink {
                            AddAccountView()
                        } label: {
                            Label("Adicionar Nova Conta", systemImage: "building.columns.fill")
                        }
                    }
                    .listRowBackground(Theme.Colors.surfaceSolid)

                    Section("Dados e Diagnóstico") {
                        Button("Rever Introdução (Onboarding)") {
                            withAnimation {
                                hasCompletedOnboarding = false
                            }
                        }
                        .foregroundStyle(Theme.Colors.primary)

                        Button("Resetar App (Apagar Tudo)", role: .destructive) {
                            showingWipeConfirmation = true
                        }
                        .foregroundStyle(Theme.Colors.error)
                        .confirmationDialog(
                            "Apagar Todos os Dados",
                            isPresented: $showingWipeConfirmation,
                            titleVisibility: .visible
                        ) {
                            Button("Apagar Tudo Permanentemente", role: .destructive, action: wipeData)
                            Button("Cancelar", role: .cancel) {}
                        } message: {
                            Text("Tem certeza que deseja apagar todas as suas contas e transações? Esta ação não pode ser desfeita.")
                        }
                    }
                    .listRowBackground(Theme.Colors.surfaceSolid)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Ajustes")
            .scrollEdgeEffectStyle(.soft, for: .top)
            .alert("Erro ao Limpar Dados", isPresented: $showingErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Ocorreu um erro inesperado.")
            }
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
            errorMessage = error.localizedDescription
            showingErrorAlert = true
        }
    }
}
