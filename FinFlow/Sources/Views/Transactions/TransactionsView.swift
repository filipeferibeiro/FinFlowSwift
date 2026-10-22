import SwiftUI
import SwiftData

public struct TransactionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("isBalanceVisible") private var isBalanceVisible: Bool = true

    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]
    @Query private var accounts: [Account]
    @Query private var creditCards: [CreditCard]

    @State private var viewModel = TransactionsViewModel()
    @State private var invoiceCardToPay: CreditCard?
    @State private var invoiceCardToInspect: CreditCard?

    public init() {}

    public var body: some View {
        let monthTransactions = TransactionService.transactions(
            for: viewModel.selectedDate,
            from: allTransactions,
            creditCards: creditCards,
            accounts: accounts
        )
        let visibleTransactions = monthTransactions.filter { viewModel.selectedFilter.matches($0) }
        let groupedTransactions = TransactionService.groupedByDay(visibleTransactions)
        let summary = TransactionService.summary(
            for: viewModel.selectedDate,
            monthTransactions: monthTransactions,
            from: allTransactions,
            creditCards: creditCards,
            accounts: accounts
        )
        let horizontalInset = horizontalSizeClass == .regular
            ? Theme.Layout.regularHorizontalPadding
            : Theme.Layout.compactHorizontalPadding

        NavigationStack {
            BaseView {
                ZStack(alignment: .top) {
                    List {
                        Spacer()
                            .frame(height: 68)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)

                        MonthOverviewView(summary: summary, isBalanceVisible: isBalanceVisible)
                            .padding(.bottom, 6)
                            .listRowInsets(EdgeInsets(top: 0, leading: horizontalInset, bottom: 0, trailing: horizontalInset))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)

                        if visibleTransactions.isEmpty {
                            ContentUnavailableView(
                                viewModel.selectedFilter == .all
                                    ? "Sem lançamentos no mês"
                                    : "Nenhum lançamento encontrado",
                                systemImage: "doc.text.magnifyingglass",
                                description: Text(
                                    viewModel.selectedFilter == .all
                                        ? "Você ainda não registrou movimentações ou faturas neste mês."
                                        : "Não há transações para o filtro '\(viewModel.selectedFilter.title)' neste mês."
                                )
                            )
                            .frame(maxWidth: .infinity, minHeight: 280)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        } else {
                            ForEach(groupedTransactions, id: \.date) { dayGroup in
                                Section {
                                    ForEach(dayGroup.transactions) { tx in
                                        Button {
                                            handleRowTap(tx)
                                        } label: {
                                            TransactionRowView(
                                                transaction: tx,
                                                isDisintegrating: viewModel.disintegratingTxIDs.contains(tx.id),
                                                isAmountVisible: isBalanceVisible
                                            )
                                        }
                                        .buttonStyle(.plain)
                                        .padding(.vertical, 4)
                                        .listRowBackground(Color.clear)
                                        .listRowSeparator(.hidden)
                                        .listRowInsets(EdgeInsets(top: 0, leading: horizontalInset, bottom: 0, trailing: horizontalInset))
                                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                            if let cardId = tx.invoiceCreditCardId,
                                               let card = creditCards.first(where: { $0.id == cardId }) {
                                                Button {
                                                    invoiceCardToInspect = card
                                                } label: {
                                                    Label("Ver Fatura", systemImage: "creditcard.fill")
                                                }
                                                .tint(Theme.Colors.primary)
                                            } else {
                                                Button {
                                                    viewModel.requestDelete(tx)
                                                } label: {
                                                    Label("Excluir", systemImage: "trash")
                                                }
                                                .tint(Theme.Colors.error)
                                            }
                                        }
                                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                            if let cardId = tx.invoiceCreditCardId,
                                               let card = creditCards.first(where: { $0.id == cardId }) {
                                                Button {
                                                    if tx.isPaid {
                                                        withAnimation {
                                                            TransactionService.reopenCreditCardInvoice(
                                                                for: card,
                                                                in: viewModel.selectedDate,
                                                                from: allTransactions,
                                                                in: modelContext
                                                            )
                                                        }
                                                    } else {
                                                        invoiceCardToPay = card
                                                    }
                                                } label: {
                                                    Label(
                                                        tx.isPaid ? "Reabrir Fatura" : "Pagar Fatura",
                                                        systemImage: tx.isPaid ? "arrow.uturn.backward.circle.fill" : "checkmark.seal.fill"
                                                    )
                                                }
                                                .tint(tx.isPaid ? Theme.Colors.warning : Theme.Colors.success)
                                            } else {
                                                Button {
                                                    withAnimation {
                                                        viewModel.togglePaid(tx, in: modelContext)
                                                    }
                                                } label: {
                                                    Label(
                                                        tx.isPaid ? "Marcar Pendente" : "Marcar Efetivado",
                                                        systemImage: tx.isPaid ? "clock.badge.exclamationmark" : "checkmark.circle.fill"
                                                    )
                                                }
                                                .tint(tx.isPaid ? Theme.Colors.warning : Theme.Colors.success)
                                            }
                                        }
                                    }
                                } header: {
                                    Text(DateUtils.formattedDay(dayGroup.date).uppercased())
                                        .font(Theme.Typography.caption1)
                                        .secondaryTextColor()
                                        .textCase(nil)
                                        .padding(.top, 12)
                                        .padding(.bottom, 4)
                                        .padding(.horizontal, horizontalInset)
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
                        .spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0.1),
                        value: visibleTransactions.map(\.id)
                    )

                    MonthSelectorView(selectedDate: viewModel.selectedDate) { delta in
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            viewModel.changeMonth(by: delta)
                        }
                    }
                    .padding(.horizontal, horizontalInset)
                    .padding(.top, 8)
                }
                .frame(maxWidth: horizontalSizeClass == .regular ? Theme.Layout.maxContentWidth : .infinity)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .bottomTrailing) {
                    FloatingActionButton {
                        viewModel.isAddingTransaction = true
                    }
                }
            }
            .navigationTitle("Extrato")
            .navigationBarTitleDisplayMode(.inline)
            .scrollEdgeEffectStyle(.soft, for: .top)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            viewModel.goToCurrentMonth()
                        }
                    } label: {
                        Image(systemName: "calendar")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(
                                viewModel.isCurrentMonth ? Theme.Colors.textSecondary : Theme.Colors.primary
                            )
                    }
                    .disabled(viewModel.isCurrentMonth)
                    .accessibilityLabel("Ir para o mês atual")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Filtrar Lançamentos", selection: $viewModel.selectedFilter.animation(.snappy)) {
                            ForEach(TransactionFilter.allCases) { filter in
                                Text(filter.title).tag(filter)
                            }
                        }
                    } label: {
                        Image(
                            systemName: viewModel.selectedFilter == .all
                                ? "line.3.horizontal.decrease.circle"
                                : "line.3.horizontal.decrease.circle.fill"
                        )
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(
                            viewModel.selectedFilter == .all ? Theme.Colors.textPrimary : Theme.Colors.primary
                        )
                    }
                    .accessibilityLabel("Filtrar lançamentos: \(viewModel.selectedFilter.title)")
                }
            }
            .navigationDestination(item: $invoiceCardToInspect) { card in
                CreditCardDetailView(card: card, initialDate: viewModel.selectedDate)
            }
            .confirmationDialog(
                "Excluir Transação",
                isPresented: $viewModel.showingDeleteAlert,
                titleVisibility: .visible,
                presenting: viewModel.transactionToDelete
            ) { tx in
                if tx.isRecurringOrInstallment {
                    Button(tx.isInstallment ? "Excluir apenas esta parcela" : "Excluir apenas esta", role: .destructive) {
                        viewModel.performDelete(tx, deleteFuture: false, in: modelContext, reduceMotion: reduceMotion)
                    }
                    Button(tx.isInstallment ? "Excluir esta e as próximas parcelas" : "Excluir esta e as próximas", role: .destructive) {
                        viewModel.performDelete(tx, deleteFuture: true, in: modelContext, reduceMotion: reduceMotion)
                    }
                    Button("Cancelar", role: .cancel) {
                        viewModel.cancelDelete()
                    }
                } else {
                    Button("Excluir", role: .destructive) {
                        viewModel.performDelete(tx, deleteFuture: false, in: modelContext, reduceMotion: reduceMotion)
                    }
                    Button("Cancelar", role: .cancel) {
                        viewModel.cancelDelete()
                    }
                }
            } message: { tx in
                Text("Deseja realmente excluir a transação '\(tx.title)' no valor de \(CurrencyFormatter.formatCurrency(tx.amountCents)) da conta \(tx.accountDisplayTitle)?\n\nEsta ação não pode ser desfeita.")
            }
            .sheet(isPresented: $viewModel.isAddingTransaction) {
                AddTransactionView()
            }
            .sheet(item: $viewModel.transactionToEdit) { tx in
                AddTransactionView(transactionToEdit: tx)
            }
            .sheet(item: $invoiceCardToPay) { card in
                PayCreditCardInvoiceView(card: card, monthDate: viewModel.selectedDate) {
                    invoiceCardToInspect = card
                }
            }
        }
    }

    private func handleRowTap(_ tx: Transaction) {
        if let cardId = tx.invoiceCreditCardId,
           let card = creditCards.first(where: { $0.id == cardId }) {
            invoiceCardToPay = card
        } else {
            viewModel.transactionToEdit = tx
        }
    }
}
