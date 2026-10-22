import SwiftUI
import SwiftData

public struct PayCreditCardInvoiceView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var accounts: [Account]
    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]

    let card: CreditCard
    let monthDate: Date
    let onViewInvoiceDetails: (() -> Void)?

    @State private var selectedAccount: Account?
    @State private var isAddingAccount = false

    public init(
        card: CreditCard,
        monthDate: Date,
        onViewInvoiceDetails: (() -> Void)? = nil
    ) {
        self.card = card
        self.monthDate = monthDate
        self.onViewInvoiceDetails = onViewInvoiceDetails
    }

    public var body: some View {
        let invoiceSummary = TransactionService.creditCardInvoiceSummary(
            for: card,
            in: monthDate,
            from: allTransactions
        )
        let cardColor = Color(hex: card.colorHex)

        NavigationStack {
            BaseView {
                ScrollView {
                    VStack(spacing: 22) {
                        invoiceSummaryCard(
                            invoiceSummary: invoiceSummary,
                            cardColor: cardColor
                        )
                        .padding(.top, 12)

                        accountSelectionSection(invoiceSummary: invoiceSummary)

                        actionButtonsSection(invoiceSummary: invoiceSummary)

                        Spacer()
                            .frame(height: 32)
                    }
                    .padding(.horizontal)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle(invoiceSummary.isFullyPaid ? "Pagamento da Fatura" : "Pagar Fatura")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if selectedAccount == nil {
                    selectedAccount = invoiceSummary.paidByAccount ?? card.paymentAccount ?? accounts.first
                }
            }
            .onChange(of: accounts) { _, newAccounts in
                if selectedAccount == nil {
                    selectedAccount = card.paymentAccount ?? newAccounts.first
                }
            }
            .sheet(isPresented: $isAddingAccount) {
                AddAccountView()
            }
        }
    }

    // MARK: - Subviews

    private func invoiceSummaryCard(
        invoiceSummary: (totalCents: Int, unpaidCents: Int, isFullyPaid: Bool, itemCount: Int, paidByAccount: Account?),
        cardColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: card.iconSystemName)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(card.name)
                        .font(Theme.Typography.headline)
                        .foregroundStyle(.white)
                }

                Spacer()

                Text(invoiceSummary.isFullyPaid ? "FATURA PAGA" : "FATURA ABERTA")
                    .font(Theme.Typography.caption2)
                    .tracking(0.8)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.20), in: .capsule)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("FATURA DE \(DateUtils.monthName(for: monthDate).uppercased()) • VENCE DIA \(card.dueDay)")
                    .font(Theme.Typography.caption2)
                    .foregroundStyle(.white.opacity(0.80))

                Text(CurrencyFormatter.formatCurrency(invoiceSummary.totalCents))
                    .font(.system(.largeTitle, design: .rounded).bold())
                    .foregroundStyle(.white)
            }

            if let paidAccount = invoiceSummary.paidByAccount, invoiceSummary.isFullyPaid {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                    Text("Débito registrado na conta \(paidAccount.name)")
                        .font(Theme.Typography.caption1)
                        .foregroundStyle(.white.opacity(0.92))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.white.opacity(0.16), in: .capsule)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [cardColor, cardColor.opacity(0.75)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: .rect(cornerRadius: Theme.Layout.cardCornerRadius)
        )
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Layout.cardCornerRadius)
                .stroke(.white.opacity(0.28), lineWidth: 1)
                .allowsHitTesting(false)
        }
        .shadow(color: cardColor.opacity(0.28), radius: 16, x: 0, y: 8)
    }

    @ViewBuilder
    private func accountSelectionSection(
        invoiceSummary: (totalCents: Int, unpaidCents: Int, isFullyPaid: Bool, itemCount: Int, paidByAccount: Account?)
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CONTA PARA DÉBITO DA FATURA")
                .font(Theme.Typography.caption1)
                .secondaryTextColor()
                .padding(.leading, 4)

            if accounts.isEmpty {
                PremiumGlassContainer(cornerRadius: Theme.Layout.cornerRadius, padding: 20) {
                    VStack(spacing: 12) {
                        Image(systemName: "building.columns.fill")
                            .font(.title2)
                            .foregroundStyle(Theme.Colors.primary)

                        Text("Nenhuma conta bancária cadastrada")
                            .font(Theme.Typography.headline)
                            .primaryTextColor()

                        Text("Cadastre uma conta para registrar o débito do pagamento desta fatura.")
                            .font(Theme.Typography.caption1)
                            .secondaryTextColor()
                            .multilineTextAlignment(.center)

                        Button {
                            isAddingAccount = true
                        } label: {
                            Label("Cadastrar Conta", systemImage: "plus")
                                .font(Theme.Typography.subheadline)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Theme.Colors.primary.gradient, in: .capsule)
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(accounts) { account in
                        let isSelected = selectedAccount?.id == account.id
                        let accountColor = Color(hex: account.colorHex)

                        Button {
                            withAnimation(.snappy) {
                                selectedAccount = account
                            }
                        } label: {
                            HStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(accountColor.gradient)
                                    .frame(width: 42, height: 42)
                                    .overlay {
                                        Image(systemName: account.iconSystemName)
                                            .font(.subheadline.bold())
                                            .foregroundStyle(.white)
                                    }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(account.name)
                                        .font(Theme.Typography.headline)
                                        .primaryTextColor()

                                    Text("Saldo atual: \(CurrencyFormatter.formatCurrency(account.currentBalanceCents))")
                                        .font(Theme.Typography.caption1)
                                        .secondaryTextColor()
                                }

                                Spacer()

                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(isSelected ? Theme.Colors.primary : Theme.Colors.textTertiary)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .glassEffectWithFallback(in: .rect(cornerRadius: Theme.Layout.cornerRadius))
                            .overlay {
                                RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius)
                                    .stroke(isSelected ? Theme.Colors.primary : Color.clear, lineWidth: 2)
                                    .allowsHitTesting(false)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                    }
                }

                if let selectedAccount, !invoiceSummary.isFullyPaid {
                    let projectedBalance = selectedAccount.currentBalanceCents - invoiceSummary.totalCents
                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundStyle(Theme.Colors.primary)
                        Text("Saldo em \(selectedAccount.name) após pagamento:")
                            .font(Theme.Typography.caption1)
                            .secondaryTextColor()
                        Spacer()
                        Text(CurrencyFormatter.formatCurrency(projectedBalance))
                            .font(.system(.caption, design: .rounded).bold())
                            .foregroundStyle(projectedBalance < 0 ? Theme.Colors.error : Theme.Colors.textPrimary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Theme.Colors.primary.opacity(0.10), in: .rect(cornerRadius: 12))
                }
            }
        }
    }

    @ViewBuilder
    private func actionButtonsSection(
        invoiceSummary: (totalCents: Int, unpaidCents: Int, isFullyPaid: Bool, itemCount: Int, paidByAccount: Account?)
    ) -> some View {
        VStack(spacing: 12) {
            if !invoiceSummary.isFullyPaid {
                Button {
                    guard let account = selectedAccount else { return }
                    TransactionService.payCreditCardInvoice(
                        for: card,
                        in: monthDate,
                        using: account,
                        from: allTransactions,
                        in: modelContext
                    )
                    dismiss()
                } label: {
                    Label("Confirmar Pagamento e Debitar Conta", systemImage: "checkmark.seal.fill")
                        .font(Theme.Typography.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            selectedAccount != nil
                                ? AnyShapeStyle(Theme.Colors.primary.gradient)
                                : AnyShapeStyle(Theme.Colors.surfaceElevated),
                            in: .rect(cornerRadius: Theme.Layout.buttonCornerRadius)
                        )
                }
                .buttonStyle(.plain)
                .disabled(selectedAccount == nil || invoiceSummary.totalCents <= 0)
            } else {
                if let selectedAccount, selectedAccount.id != invoiceSummary.paidByAccount?.id {
                    Button {
                        TransactionService.payCreditCardInvoice(
                            for: card,
                            in: monthDate,
                            using: selectedAccount,
                            from: allTransactions,
                            in: modelContext
                        )
                        dismiss()
                    } label: {
                        Label("Alterar Débito para \(selectedAccount.name)", systemImage: "arrow.triangle.2.circlepath")
                            .font(Theme.Typography.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Theme.Colors.primary.gradient, in: .rect(cornerRadius: Theme.Layout.buttonCornerRadius))
                    }
                    .buttonStyle(.plain)
                }

                Button(role: .destructive) {
                    TransactionService.reopenCreditCardInvoice(
                        for: card,
                        in: monthDate,
                        from: allTransactions,
                        in: modelContext
                    )
                    dismiss()
                } label: {
                    Label("Reabrir Fatura e Estornar Débito", systemImage: "arrow.uturn.backward.circle.fill")
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Colors.warning)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            Theme.Colors.warning.opacity(0.15),
                            in: .rect(cornerRadius: Theme.Layout.buttonCornerRadius)
                        )
                }
                .buttonStyle(.plain)
            }

            if let onViewInvoiceDetails {
                Button {
                    dismiss()
                    onViewInvoiceDetails()
                } label: {
                    Label("Ver Detalhamento da Fatura (\(invoiceSummary.itemCount) itens)", systemImage: "list.bullet.rectangle.portrait")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.Colors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .glassEffectWithFallback(in: .rect(cornerRadius: Theme.Layout.buttonCornerRadius))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
