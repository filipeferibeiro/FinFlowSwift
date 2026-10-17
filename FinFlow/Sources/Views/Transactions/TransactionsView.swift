import SwiftUI
import SwiftData

public struct TransactionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]
    @Query private var accounts: [Account]

    @State private var viewModel = TransactionsViewModel()

    public init() {}

    public var body: some View {
        let monthTransactions = TransactionService.transactions(
            for: viewModel.selectedDate,
            from: allTransactions
        )
        let groupedTransactions = TransactionService.groupedByDay(monthTransactions)
        let summary = TransactionService.summary(
            for: monthTransactions,
            accounts: accounts
        )

        NavigationStack {
            BaseView {
                ZStack(alignment: .top) {
                    List {
                        Spacer()
                            .frame(height: 90)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)

                        MonthOverviewView(summary: summary)
                            .padding(.bottom, 8)
                            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)

                        if monthTransactions.isEmpty {
                            ContentUnavailableView(
                                "Sem transações no mês",
                                systemImage: "tray.fill",
                                description: Text("Você ainda não registrou nada neste mês.")
                            )
                            .frame(maxWidth: .infinity, minHeight: 320)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        } else {
                            ForEach(groupedTransactions, id: \.date) { dayGroup in
                                Section {
                                    ForEach(dayGroup.transactions) { tx in
                                        Button {
                                            viewModel.transactionToEdit = tx
                                        } label: {
                                            TransactionRowView(
                                                transaction: tx,
                                                isDisintegrating: viewModel.disintegratingTxIDs.contains(tx.id)
                                            )
                                        }
                                        .buttonStyle(.plain)
                                        .padding(.vertical, 4)
                                        .listRowBackground(Color.clear)
                                        .listRowSeparator(.hidden)
                                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                            Button {
                                                viewModel.requestDelete(tx)
                                            } label: {
                                                Label("Excluir", systemImage: "trash")
                                            }
                                            .tint(Theme.Colors.error)
                                        }
                                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                            Button {
                                                withAnimation {
                                                    viewModel.togglePaid(tx, in: modelContext)
                                                }
                                            } label: {
                                                Label(
                                                    tx.isPaid ? "Marcar Pendente" : "Marcar Pago",
                                                    systemImage: tx.isPaid ? "xmark.circle" : "checkmark.circle"
                                                )
                                            }
                                            .tint(tx.isPaid ? Theme.Colors.warning : Theme.Colors.success)
                                        }
                                    }
                                } header: {
                                    Text(DateUtils.formattedDay(dayGroup.date))
                                        .font(Theme.Typography.headline)
                                        .primaryTextColor()
                                        .textCase(nil)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                }
                                .listRowInsets(EdgeInsets())
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.plain)
                    .scrollIndicators(.hidden)
                    .animation(
                        .spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0.1),
                        value: monthTransactions.map(\.id)
                    )

                    MonthSelectorView(selectedDate: viewModel.selectedDate) { delta in
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            viewModel.changeMonth(by: delta)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
                .overlay(alignment: .bottomTrailing) {
                    FloatingActionButton {
                        viewModel.isAddingTransaction = true
                    }
                }
            }
            .navigationTitle("Extrato")
            .navigationBarTitleDisplayMode(.inline)
            .scrollEdgeEffectStyle(.soft, for: .top)
            .confirmationDialog(
                "Excluir Transação",
                isPresented: $viewModel.showingDeleteAlert,
                titleVisibility: .visible,
                presenting: viewModel.transactionToDelete
            ) { tx in
                if tx.isFixed {
                    Button("Excluir apenas esta", role: .destructive) {
                        viewModel.performDelete(tx, deleteFuture: false, in: modelContext, reduceMotion: reduceMotion)
                    }
                    Button("Excluir esta e as próximas", role: .destructive) {
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
        }
    }
}
