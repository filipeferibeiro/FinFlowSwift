import SwiftUI
import SwiftData

public struct HomeView: View {
    @AppStorage("userName") private var userName: String = "Usuário"
    @Query private var accounts: [Account]
    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]

    @ScaledMetric(relativeTo: .largeTitle) private var heroBalanceSize: Double = 48

    @State private var isBalanceVisible: Bool = true
    @State private var isAddingTransaction: Bool = false
    @State private var isAddingAccount: Bool = false
    @State private var accountToEdit: Account?

    private var currentMonthSummary: MonthSummary {
        let monthTransactions = TransactionService.transactions(for: .now, from: allTransactions)
        return TransactionService.summary(for: monthTransactions, accounts: accounts)
    }

    public init() {}

    public var body: some View {
        let summary = currentMonthSummary

        NavigationStack {
            BaseView {
                ScrollView {
                    VStack(spacing: Theme.Layout.standardPadding) {
                        balanceHeader(totalBalanceCents: summary.currentBalanceCents)

                        monthQuickSummarySection(summary: summary)

                        accountsSection

                        Spacer()
                            .frame(height: 100)
                    }
                    .padding()
                }
                .scrollIndicators(.hidden)
                .overlay(alignment: .bottomTrailing) {
                    FloatingActionButton {
                        isAddingTransaction = true
                    }
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .scrollEdgeEffectStyle(.soft, for: .top)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(
                        isBalanceVisible ? "Ocultar Saldo" : "Mostrar Saldo",
                        systemImage: isBalanceVisible ? "eye.fill" : "eye.slash.fill",
                        action: toggleBalanceVisibility
                    )
                    .labelStyle(.iconOnly)
                    .foregroundStyle(Theme.Colors.primary)
                }
            }
            .sheet(isPresented: $isAddingTransaction) {
                AddTransactionView()
            }
            .sheet(isPresented: $isAddingAccount) {
                AddAccountView()
            }
            .sheet(item: $accountToEdit) { account in
                AddAccountView(accountToEdit: account)
            }
        }
    }

    // MARK: - Actions

    private func toggleBalanceVisibility() {
        withAnimation(.easeInOut) {
            isBalanceVisible.toggle()
        }
    }

    // MARK: - Subviews

    private func balanceHeader(totalBalanceCents: Int) -> some View {
        VStack(spacing: 8) {
            Text("\(DateUtils.greeting()), \(userName)")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.textSecondary)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("R$")
                    .font(.system(.title, design: .rounded).weight(.medium))
                    .foregroundStyle(Theme.Colors.textTertiary)

                Text(isBalanceVisible ? CurrencyFormatter.formatDecimal(totalBalanceCents) : "•••••")
                    .font(.system(size: heroBalanceSize, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .contentTransition(.numericText())
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Saldo total: \(isBalanceVisible ? CurrencyFormatter.formatCurrency(totalBalanceCents) : "oculto")")
        }
        .padding(.top, 16)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func monthQuickSummarySection(summary: MonthSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Resumo de \(DateUtils.monthName(for: .now))")
                .font(Theme.Typography.headline)
                .primaryTextColor()
                .accessibilityAddTraits(.isHeader)

            FallbackGlassContainer(spacing: 16) {
                HStack(spacing: 16) {
                    summaryCard(
                        title: "Entradas",
                        icon: "arrow.down.left",
                        amountCents: summary.monthIncomeCents,
                        color: Theme.Colors.success
                    )

                    summaryCard(
                        title: "Saídas",
                        icon: "arrow.up.right",
                        amountCents: summary.monthExpenseCents,
                        color: Theme.Colors.error
                    )
                }
            }
        }
    }

    private func summaryCard(title: String, icon: String, amountCents: Int, color: Color) -> some View {
        PremiumGlassContainer(cornerRadius: Theme.Layout.cornerRadius, padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.headline.bold())
                        .foregroundStyle(color)

                    Text(title)
                        .font(Theme.Typography.subheadline)
                        .secondaryTextColor()
                }

                Text(isBalanceVisible ? CurrencyFormatter.formatCurrency(amountCents) : "R$ •••••")
                    .font(.system(.headline, design: .rounded).bold())
                    .primaryTextColor()
                    .contentTransition(.numericText())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) no mês: \(isBalanceVisible ? CurrencyFormatter.formatCurrency(amountCents) : "oculto")")
    }

    private var accountsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Minhas Contas")
                    .font(Theme.Typography.headline)
                    .primaryTextColor()
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                Button("Nova Conta", systemImage: "plus.circle.fill") {
                    isAddingAccount = true
                }
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.primary)
            }

            if accounts.isEmpty {
                PremiumGlassContainer(cornerRadius: Theme.Layout.cornerRadius, padding: 24) {
                    ContentUnavailableView(
                        "Nenhuma conta cadastrada",
                        systemImage: "building.columns",
                        description: Text("Adicione uma conta para acompanhar seu saldo.")
                    )
                }
            } else {
                FallbackGlassContainer(spacing: 12) {
                    VStack(spacing: 12) {
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
}
