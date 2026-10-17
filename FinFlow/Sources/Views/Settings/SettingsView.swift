import SwiftUI
import SwiftData

public struct SettingsView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("userName") private var userName: String = "Usuário"
    @Environment(\.modelContext) private var modelContext
    @Query private var accounts: [Account]
    @Query private var creditCards: [CreditCard]
    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]

    @State private var isAddingAccount = false
    @State private var isAddingCreditCard = false
    @State private var accountToEdit: Account?
    @State private var cardToEdit: CreditCard?
    @State private var showingWipeConfirmation = false
    @State private var errorMessage: String?
    @State private var showingErrorAlert = false

    public init() {}

    public var body: some View {
        NavigationStack {
            BaseView {
                ScrollView {
                    VStack(spacing: 24) {
                        profileSection

                        accountsManagementSection

                        creditCardsManagementSection

                        systemSection

                        Spacer()
                            .frame(height: 60)
                    }
                    .padding()
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.inline)
            .scrollEdgeEffectStyle(.soft, for: .top)
            .sheet(isPresented: $isAddingAccount) {
                AddAccountView()
            }
            .sheet(isPresented: $isAddingCreditCard) {
                AddCreditCardView()
            }
            .sheet(item: $accountToEdit) { account in
                AddAccountView(accountToEdit: account)
            }
            .sheet(item: $cardToEdit) { card in
                AddCreditCardView(cardToEdit: card)
            }
            .confirmationDialog(
                "Apagar Todos os Dados",
                isPresented: $showingWipeConfirmation,
                titleVisibility: .visible
            ) {
                Button("Apagar Tudo Permanentemente", role: .destructive, action: wipeData)
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Tem certeza que deseja apagar todas as suas contas, cartões e lançamentos? Esta ação é irreversível.")
            }
            .alert("Erro ao Limpar Dados", isPresented: $showingErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Ocorreu um erro inesperado.")
            }
        }
    }

    // MARK: - Sections

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PERFIL")
                .font(Theme.Typography.caption1)
                .secondaryTextColor()
                .padding(.leading, 4)

            PremiumGlassContainer(cornerRadius: Theme.Layout.cornerRadius, padding: 16) {
                HStack(spacing: 14) {
                    Circle()
                        .fill(Theme.Colors.primary.gradient)
                        .frame(width: 52, height: 52)
                        .overlay {
                            Text(String(userName.prefix(1)).uppercased())
                                .font(.system(.title3, design: .rounded).bold())
                                .foregroundStyle(.white)
                        }
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Como devemos chamar você?")
                            .font(Theme.Typography.caption1)
                            .secondaryTextColor()

                        TextField("Seu nome", text: $userName)
                            .font(Theme.Typography.headline)
                            .primaryTextColor()
                    }
                }
            }
        }
    }

    private var accountsManagementSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("CONTAS BANCÁRIAS")
                    .font(Theme.Typography.caption1)
                    .secondaryTextColor()
                    .padding(.leading, 4)

                Spacer()

                Button {
                    isAddingAccount = true
                } label: {
                    Label("Nova Conta", systemImage: "plus")
                        .font(Theme.Typography.caption1)
                        .foregroundStyle(Theme.Colors.primary)
                }
            }

            FallbackGlassContainer(spacing: 10) {
                VStack(spacing: 10) {
                    ForEach(accounts) { account in
                        Button {
                            accountToEdit = account
                        } label: {
                            AccountRowView(account: account, isBalanceVisible: true)
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        isAddingAccount = true
                    } label: {
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Theme.Colors.primary.opacity(0.14))
                                .frame(width: 42, height: 42)
                                .overlay {
                                    Image(systemName: "plus")
                                        .font(.headline.bold())
                                        .foregroundStyle(Theme.Colors.primary)
                                }

                            Text("Adicionar Nova Conta Bancária")
                                .font(Theme.Typography.subheadline)
                                .foregroundStyle(Theme.Colors.primary)

                            Spacer()
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glassEffectWithFallback(in: .rect(cornerRadius: Theme.Layout.cornerRadius), interactive: true)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var creditCardsManagementSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("CARTÕES DE CRÉDITO")
                    .font(Theme.Typography.caption1)
                    .secondaryTextColor()
                    .padding(.leading, 4)

                Spacer()

                Button {
                    isAddingCreditCard = true
                } label: {
                    Label("Novo Cartão", systemImage: "plus")
                        .font(Theme.Typography.caption1)
                        .foregroundStyle(Theme.Colors.primary)
                }
            }

            FallbackGlassContainer(spacing: 10) {
                VStack(spacing: 10) {
                    ForEach(creditCards) { card in
                        let invoice = TransactionService.creditCardInvoiceSummary(
                            for: card,
                            in: .now,
                            from: allTransactions
                        )
                        let usedLimit = TransactionService.creditCardUsedLimitCents(
                            for: card,
                            from: allTransactions
                        )

                        Button {
                            cardToEdit = card
                        } label: {
                            CreditCardRowView(
                                card: card,
                                invoiceTotalCents: invoice.totalCents,
                                isInvoicePaid: invoice.isFullyPaid,
                                usedLimitCents: usedLimit,
                                isBalanceVisible: true
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        isAddingCreditCard = true
                    } label: {
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Theme.Colors.primary.opacity(0.14))
                                .frame(width: 42, height: 42)
                                .overlay {
                                    Image(systemName: "creditcard.fill")
                                        .font(.headline.bold())
                                        .foregroundStyle(Theme.Colors.primary)
                                }

                            Text("Adicionar Novo Cartão de Crédito")
                                .font(Theme.Typography.subheadline)
                                .foregroundStyle(Theme.Colors.primary)

                            Spacer()
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glassEffectWithFallback(in: .rect(cornerRadius: Theme.Layout.cornerRadius), interactive: true)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var systemSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SISTEMA E DADOS")
                .font(Theme.Typography.caption1)
                .secondaryTextColor()
                .padding(.leading, 4)

            FallbackGlassContainer(spacing: 10) {
                VStack(spacing: 10) {
                    Button {
                        withAnimation {
                            hasCompletedOnboarding = false
                        }
                    } label: {
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Theme.Colors.primary.opacity(0.14))
                                .frame(width: 40, height: 40)
                                .overlay {
                                    Image(systemName: "sparkles")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(Theme.Colors.primary)
                                }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Rever Apresentação Inicial")
                                    .font(Theme.Typography.subheadline)
                                    .primaryTextColor()
                                Text("Voltar para o fluxo de boas-vindas")
                                    .font(Theme.Typography.caption2)
                                    .secondaryTextColor()
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption.bold())
                                .foregroundStyle(Theme.Colors.textTertiary)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glassEffectWithFallback(in: .rect(cornerRadius: Theme.Layout.cornerRadius), interactive: true)
                    }
                    .buttonStyle(.plain)

                    Button(role: .destructive) {
                        showingWipeConfirmation = true
                    } label: {
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Theme.Colors.error.opacity(0.14))
                                .frame(width: 40, height: 40)
                                .overlay {
                                    Image(systemName: "trash.fill")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(Theme.Colors.error)
                                }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Redefinir Aplicativo")
                                    .font(Theme.Typography.subheadline)
                                    .foregroundStyle(Theme.Colors.error)
                                Text("Apagar todas as contas, cartões e lançamentos")
                                    .font(Theme.Typography.caption2)
                                    .secondaryTextColor()
                            }

                            Spacer()
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glassEffectWithFallback(in: .rect(cornerRadius: Theme.Layout.cornerRadius), interactive: true)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func wipeData() {
        do {
            try modelContext.delete(model: Account.self)
            try modelContext.delete(model: CreditCard.self)
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
