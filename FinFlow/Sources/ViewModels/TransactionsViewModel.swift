import SwiftUI
import SwiftData

@Observable
public final class TransactionsViewModel {
    public var selectedDate: Date = .now
    public var selectedFilter: TransactionFilter = .all
    public var transactionToDelete: Transaction?
    public var showingDeleteAlert: Bool = false
    public var transactionToEdit: Transaction?
    public var isAddingTransaction: Bool = false
    public var disintegratingTxIDs: Set<UUID> = []

    public init() {}

    public var isCurrentMonth: Bool {
        Calendar.current.isDate(selectedDate, equalTo: .now, toGranularity: .month)
    }

    public func changeMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: selectedDate) {
            selectedDate = newDate
        }
    }

    public func goToCurrentMonth() {
        selectedDate = .now
    }

    public func requestDelete(_ tx: Transaction) {
        transactionToDelete = tx
        showingDeleteAlert = true
    }

    public func cancelDelete() {
        transactionToDelete = nil
    }

    public func togglePaid(_ tx: Transaction, in context: ModelContext) {
        TransactionService.togglePaid(tx, in: context)
    }

    public func performDelete(
        _ tx: Transaction,
        deleteFuture: Bool,
        in context: ModelContext,
        reduceMotion: Bool
    ) {
        let targetID = tx.id
        transactionToDelete = nil

        if reduceMotion {
            TransactionService.delete(tx, deleteFuture: deleteFuture, in: context)
            return
        }

        withAnimation(.easeOut(duration: 0.6)) {
            _ = disintegratingTxIDs.insert(targetID)
        }

        Task {
            try? await Task.sleep(for: .milliseconds(600))
            TransactionService.delete(tx, deleteFuture: deleteFuture, in: context)
            try? await Task.sleep(for: .milliseconds(600))
            disintegratingTxIDs.remove(targetID)
        }
    }
}
