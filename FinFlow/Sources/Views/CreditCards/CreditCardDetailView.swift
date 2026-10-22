import SwiftUI
import SwiftData

public struct CreditCardDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("isBalanceVisible") private var isBalanceVisible: Bool = true

    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]

    let card: CreditCard

    @State private var selectedDate: Date
    @State private var isAddingPurchase = false
    @State private var isEditingCard = false
    @State private var isManagingInvoicePayment = false
    @State private var transactionToEdit: Transaction?
    @State private var transactionToDelete: Transaction?
    @State private var showingDeleteDialog = false
    @State private var disintegratingTxIDs: Set<UUID> = []

    public init(card: CreditCard, initialDate: Date = .now) {
        self.card = card
        _selectedDate = State(initialValue: initialDate)
    }

    public var body: some View {
        let invoiceItems = TransactionService.creditCardTransactions(
            for: card,
            in: selectedDate,
            from: allTransactions
        )
        let groupedItems = TransactionService.groupedByDay(invoiceItems)
        let invoiceSummary = TransactionService.creditCardInvoiceSummary(
            for: card,
            in: selectedDate,
            from: allTransactions
        )
        let usedLimitCents = TransactionService.creditCardUsedLimitCents(
            for: card,
            from: allTransactions
        )

        BaseView {
            ZStack(alignment: .top) {
                List {
                    Spacer()
                        .frame(height: 76)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)

                    invoiceHeroCard(
                        invoiceSummary: invoiceSummary,
                        usedLimitCents: usedLimitCents
                    )
                    .padding(.bottom, 8)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                    if invoiceItems.isEmpty {
                        ContentUnavailableView(
                            "Fatura sem lançamentos",
                            systemImage: "creditcard",
                            description: Text("Nenhuma compra ou parcela registrada para \(DateUtils.monthName(for: selectedDate)).")
                        )
                        .frame(maxWidth: .infinity, minHeight: 240)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    } else {
                        ForEach(groupedItems, id: \.date) { dayGroup in
                            Section {
                                ForEach(dayGroup.transactions) { tx in
                                    Button {
                                        transactionToEdit = tx
                                    } label: {
                                        TransactionRowView(
                                            transaction: tx,
                                            isDisintegrating: disintegratingTxIDs.contains(tx.id),
                                            isAmountVisible: isBalanceVisible
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.vertical, 4)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button {
                                            transactionToDelete = tx
                                            showingDeleteDialog = true
                                        } label: {
                                            Label("Excluir", systemImage: "trash")
                                        }
                                        .tint(Theme.Colors.error)
                                    }
                                }
                            } header: {
                                Text(DateUtils.formattedDay(dayGroup.date).uppercased())
                                    .font(Theme.Typography.caption1)
                                    .secondaryTextColor()
                                    .textCase(nil)
                                    .padding(.top, 12)
                                    .padding(.bottom, 4)
                                    .padding(.horizontal, 16)
                            }
                            .listRowInsets(EdgeInsets())
                        }

                        Spacer()
                            .frame(height: 80)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.plain)
                .scrollIndicators(.hidden)
                .animation(
                    .spring(response: 0.35, dampingFraction: 0.8),
                    value: invoiceItems.map(\.id)
                )

                monthHeaderBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            }
            .overlay(alignment: .bottomTrailing) {
                FloatingActionButton(title: "Nova Compra no Cartão") {
                    isAddingPurchase = true
                }
            }
        }
        .navigationTitle(card.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .scrollEdgeEffectStyle(.soft, for: .top)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Editar Cartão", systemImage: "slider.horizontal.3") {
                    isEditingCard = true
                }
                .foregroundStyle(Theme.Colors.primary)
            }
        }
        .confirmationDialog(
            "Excluir Item da Fatura",
            isPresented: $showingDeleteDialog,
            titleVisibility: .visible,
            presenting: transactionToDelete
        ) { tx in
            if tx.isRecurringOrInstallment {
                Button(tx.isInstallment ? "Excluir apenas esta parcela" : "Excluir apenas este mês", role: .destructive) {
                    performDelete(tx, deleteFuture: false)
                }
                Button(tx.isInstallment ? "Excluir esta e as próximas parcelas" : "Excluir este e os próximos", role: .destructive) {
                    performDelete(tx, deleteFuture: true)
                }
                Button("Cancelar", role: .cancel) {
                    transactionToDelete = nil
                }
            } else {
                Button("Excluir Compra", role: .destructive) {
                    performDelete(tx, deleteFuture: false)
                }
                Button("Cancelar", role: .cancel) {
                    transactionToDelete = nil
                }
            }
        } message: { tx in
            Text("Deseja excluir '\(tx.title)' (\(CurrencyFormatter.formatCurrency(tx.amountCents))) da fatura do cartão \(card.name)?")
        }
        .sheet(isPresented: $isAddingPurchase) {
            AddTransactionView(initialType: .expense, preselectedCreditCard: card)
        }
        .sheet(item: $transactionToEdit) { tx in
            AddTransactionView(transactionToEdit: tx)
        }
        .sheet(isPresented: $isEditingCard) {
            AddCreditCardView(cardToEdit: card)
        }
        .sheet(isPresented: $isManagingInvoicePayment) {
            PayCreditCardInvoiceView(card: card, monthDate: selectedDate)
        }
    }

    // MARK: - Subviews

    private var monthHeaderBar: some View {
        PremiumGlassContainer(cornerRadius: Theme.Layout.buttonCornerRadius, padding: 4) {
            HStack {
                Button {
                    changeMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .frame(width: 44, height: 44)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Fatura anterior")

                Spacer()

                Text("Fatura de \(DateUtils.monthName(for: selectedDate))")
                    .font(Theme.Typography.headline)
                    .primaryTextColor()

                Spacer()

                Button {
                    changeMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .frame(width: 44, height: 44)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Próxima fatura")
            }
        }
    }

    private func invoiceHeroCard(
        invoiceSummary: (totalCents: Int, unpaidCents: Int, isFullyPaid: Bool, itemCount: Int, paidByAccount: Account?),
        usedLimitCents: Int
    ) -> some View {
        let cardColor = Color(hex: card.colorHex)
        let availableLimitCents = max(0, card.limitCents - usedLimitCents)
        let usageRatio = card.limitCents > 0
            ? min(max(Double(usedLimitCents) / Double(card.limitCents), 0.0), 1.0)
            : 0.0

        return VStack(alignment: .leading, spacing: 18) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: card.iconSystemName)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("Fecha dia \(card.closingDay) • Vence dia \(card.dueDay)")
                        .font(Theme.Typography.caption1)
                        .foregroundStyle(.white.opacity(0.85))
                }

                Spacer()

                Text(invoiceSummary.itemCount == 0 ? "ZERADA" : (invoiceSummary.isFullyPaid ? "PAGA" : "ABERTA"))
                    .font(Theme.Typography.caption2)
                    .tracking(0.8)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.20), in: .capsule)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("TOTAL DA FATURA")
                    .font(Theme.Typography.caption2)
                    .foregroundStyle(.white.opacity(0.75))

                Text(isBalanceVisible ? CurrencyFormatter.formatCurrency(invoiceSummary.totalCents) : "R$ •••••")
                    .font(.system(.largeTitle, design: .rounded).bold())
                    .foregroundStyle(.white)

                if let paidAccount = invoiceSummary.paidByAccount, invoiceSummary.isFullyPaid {
                    HStack(spacing: 5) {
                        Image(systemName: "building.columns.fill")
                            .font(.caption2)
                        Text("Débito registrado em \(paidAccount.name)")
                            .font(Theme.Typography.caption1)
                    }
                    .foregroundStyle(.white.opacity(0.90))
                } else if let defaultAccount = card.paymentAccount {
                    HStack(spacing: 5) {
                        Image(systemName: "building.columns")
                            .font(.caption2)
                        Text("Conta de débito: \(defaultAccount.name)")
                            .font(Theme.Typography.caption1)
                    }
                    .foregroundStyle(.white.opacity(0.80))
                }
            }

            // Limit Progress Bar
            VStack(spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.white.opacity(0.20))

                        Capsule()
                            .fill(.white)
                            .frame(width: max(6, geo.size.width * usageRatio))
                    }
                }
                .frame(height: 6)

                HStack {
                    Text("Utilizado: \(isBalanceVisible ? CurrencyFormatter.formatCurrency(usedLimitCents) : "R$ ••••")")
                        .font(Theme.Typography.caption2)
                        .foregroundStyle(.white.opacity(0.80))

                    Spacer()

                    Text("Disponível: \(isBalanceVisible ? CurrencyFormatter.formatCurrency(availableLimitCents) : "R$ ••••")")
                        .font(Theme.Typography.caption2)
                        .foregroundStyle(.white)
                }
            }

            if invoiceSummary.itemCount > 0 {
                HStack(spacing: 12) {
                    Button {
                        isManagingInvoicePayment = true
                    } label: {
                        Label(
                            invoiceSummary.isFullyPaid ? "Gerenciar Pagamento" : "Pagar Fatura",
                            systemImage: invoiceSummary.isFullyPaid ? "building.columns.fill" : "checkmark.seal.fill"
                        )
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(cardColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.white, in: .rect(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)

                    Button {
                        isAddingPurchase = true
                    } label: {
                        Label("Nova Compra", systemImage: "plus")
                            .font(Theme.Typography.subheadline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(.white.opacity(0.18), in: .rect(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
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
        .shadow(color: cardColor.opacity(0.28), radius: 18, x: 0, y: 8)
    }

    // MARK: - Actions

    private func changeMonth(by delta: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: delta, to: selectedDate) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selectedDate = newDate
            }
        }
    }

    private func performDelete(_ tx: Transaction, deleteFuture: Bool) {
        let targetID = tx.id
        transactionToDelete = nil

        if reduceMotion {
            TransactionService.delete(tx, deleteFuture: deleteFuture, in: modelContext)
            return
        }

        withAnimation(.easeOut(duration: 0.6)) {
            _ = disintegratingTxIDs.insert(targetID)
        }

        Task {
            try? await Task.sleep(for: .milliseconds(600))
            TransactionService.delete(tx, deleteFuture: deleteFuture, in: modelContext)
            try? await Task.sleep(for: .milliseconds(600))
            disintegratingTxIDs.remove(targetID)
        }
    }
}
