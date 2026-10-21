import SwiftUI
import SwiftData

public struct HomeView: View {
    @AppStorage("userName") private var userName: String = "Usuário"
    @AppStorage("isBalanceVisible") private var isBalanceVisible: Bool = true

    @Query private var accounts: [Account]
    @Query private var creditCards: [CreditCard]
    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]

    @State private var activeTransactionType: TransactionType?
    @State private var isAddingAccount: Bool = false
    @State private var isAddingCreditCard: Bool = false
    @State private var accountToEdit: Account?

    public init() {}

    public var body: some View {
        let monthTransactions = TransactionService.transactions(
            for: .now,
            from: allTransactions,
            creditCards: creditCards,
            accounts: accounts
        )
        let summary = TransactionService.summary(
            for: .now,
            monthTransactions: monthTransactions,
            from: allTransactions,
            creditCards: creditCards,
            accounts: accounts
        )

        NavigationStack {
            BaseView {
                ScrollView {
                    VStack(spacing: 24) {
                        headerBar

                        HeroBalanceCardView(
                            summary: summary,
                            isBalanceVisible: isBalanceVisible,
                            monthTitle: DateUtils.monthName(for: .now)
                        )

                        quickActionsRow

                        accountsSection

                        creditCardsSection

                        Spacer()
                            .frame(height: 90)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                .scrollIndicators(.hidden)
                .overlay(alignment: .bottomTrailing) {
                    FloatingActionButton {
                        activeTransactionType = .expense
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $activeTransactionType) { selectedType in
                AddTransactionView(initialType: selectedType)
            }
            .sheet(isPresented: $isAddingAccount) {
                AddAccountView()
            }
            .sheet(isPresented: $isAddingCreditCard) {
                AddCreditCardView()
            }
            .sheet(item: $accountToEdit) { account in
                AddAccountView(accountToEdit: account)
            }
        }
    }

    // MARK: - Actions

    private func toggleBalanceVisibility() {
        withAnimation(.snappy) {
            isBalanceVisible.toggle()
        }
    }

    // MARK: - Subviews

    private var headerBar: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Theme.Colors.primary.gradient)
                .frame(width: 44, height: 44)
                .overlay {
                    Text(String(userName.prefix(1)).uppercased())
                        .font(.system(.headline, design: .rounded).bold())
                        .foregroundStyle(.white)
                }
                .shadow(color: Theme.Colors.primary.opacity(0.25), radius: 8, x: 0, y: 4)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(DateUtils.greeting()), \(userName)")
                    .font(Theme.Typography.title3)
                    .primaryTextColor()

                Text("Visão Geral do Patrimônio")
                    .font(Theme.Typography.caption1)
                    .secondaryTextColor()
            }

            Spacer()

            Button(action: toggleBalanceVisibility) {
                Image(systemName: isBalanceVisible ? "eye.fill" : "eye.slash.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.Colors.primary)
                    .frame(width: 44, height: 44)
                    .glassEffectWithFallback(in: .circle)
            }
            .buttonStyle(.plain)
            .contentShape(.circle)
            .accessibilityLabel(isBalanceVisible ? "Ocultar valores" : "Mostrar valores")
        }
        .padding(.top, 4)
    }

    private var quickActionsRow: some View {
        FallbackGlassContainer(spacing: 12) {
            HStack(spacing: 12) {
                quickActionButton(
                    title: "Despesa",
                    icon: "arrow.up.right",
                    color: Theme.Colors.error
                ) {
                    activeTransactionType = .expense
                }

                quickActionButton(
                    title: "Receita",
                    icon: "arrow.down.left",
                    color: Theme.Colors.success
                ) {
                    activeTransactionType = .income
                }

                quickActionButton(
                    title: "Transferência",
                    icon: "arrow.left.arrow.right",
                    color: Theme.Colors.primary
                ) {
                    activeTransactionType = .transfer
                }
            }
        }
    }

    private func quickActionButton(
        title: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: icon)
                            .font(.subheadline.bold())
                            .foregroundStyle(color)
                    }

                Text(title)
                    .font(Theme.Typography.caption1)
                    .primaryTextColor()
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .glassEffectWithFallback(in: .rect(cornerRadius: Theme.Layout.cornerRadius))
        }
        .buttonStyle(.plain)
    }

    private var accountsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Minhas Contas")
                    .font(Theme.Typography.headline)
                    .primaryTextColor()
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                Button {
                    isAddingAccount = true
                } label: {
                    Label("Adicionar", systemImage: "plus")
                        .font(Theme.Typography.caption1)
                        .foregroundStyle(Theme.Colors.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Theme.Colors.primary.opacity(0.12), in: .capsule)
                }
            }

            if accounts.isEmpty {
                PremiumGlassContainer(cornerRadius: Theme.Layout.cornerRadius, padding: 24) {
                    ContentUnavailableView(
                        "Nenhuma conta cadastrada",
                        systemImage: "building.columns",
                        description: Text("Adicione sua primeira conta bancária ou carteira para acompanhar seu saldo.")
                    )
                }
            } else {
                FallbackGlassContainer(spacing: 10) {
                    VStack(spacing: 10) {
                        ForEach(accounts) { account in
                            Button {
                                accountToEdit = account
                            } label: {
                                AccountRowView(
                                    account: account,
                                    isBalanceVisible: isBalanceVisible
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var creditCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Cartões de Crédito")
                    .font(Theme.Typography.headline)
                    .primaryTextColor()
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                Button {
                    isAddingCreditCard = true
                } label: {
                    Label("Adicionar", systemImage: "plus")
                        .font(Theme.Typography.caption1)
                        .foregroundStyle(Theme.Colors.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Theme.Colors.primary.opacity(0.12), in: .capsule)
                }
            }

            if creditCards.isEmpty {
                PremiumGlassContainer(cornerRadius: Theme.Layout.cornerRadius, padding: 20) {
                    HStack(spacing: 14) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Theme.Colors.primary.opacity(0.14))
                            .frame(width: 44, height: 44)
                            .overlay {
                                Image(systemName: "creditcard.fill")
                                    .font(.headline)
                                    .foregroundStyle(Theme.Colors.primary)
                            }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Nenhum cartão cadastrado")
                                .font(Theme.Typography.subheadline)
                                .primaryTextColor()
                            Text("Adicione seus cartões para controlar faturas e compras parceladas.")
                                .font(Theme.Typography.caption2)
                                .secondaryTextColor()
                        }

                        Spacer()
                    }
                }
            } else {
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

                            NavigationLink {
                                CreditCardDetailView(card: card)
                            } label: {
                                CreditCardRowView(
                                    card: card,
                                    invoiceTotalCents: invoice.totalCents,
                                    isInvoicePaid: invoice.isFullyPaid,
                                    usedLimitCents: usedLimit,
                                    isBalanceVisible: isBalanceVisible
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}
