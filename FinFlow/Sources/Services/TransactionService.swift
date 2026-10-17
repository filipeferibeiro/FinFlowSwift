import Foundation
import SwiftData

public enum TransactionService {
    /// Computes the active list of materialized + virtual recurring transactions for `monthDate`.
    public static func transactions(
        for monthDate: Date,
        from allTransactions: [Transaction],
        calendar: Calendar = .current
    ) -> [Transaction] {
        guard let (startOfMonth, endOfMonth) = DateUtils.monthBounds(for: monthDate, calendar: calendar) else {
            return []
        }

        let targetMonthKey = DateUtils.monthKey(for: monthDate)
        var results: [Transaction] = []
        var overriddenTemplateIds = Set<UUID>()

        // 1. Register all template overrides targeting this month (even if their date was moved)
        for tx in allTransactions {
            if let templateId = tx.recurringGroupId {
                if tx.recurringMonth == targetMonthKey || calendar.isDate(tx.date, equalTo: monthDate, toGranularity: .month) {
                    overriddenTemplateIds.insert(templateId)
                }
            }
        }

        // 2. Collect materialized transactions falling in this month
        for tx in allTransactions {
            guard calendar.isDate(tx.date, equalTo: monthDate, toGranularity: .month) else { continue }

            if tx.isFixed && tx.recurringGroupId == nil {
                // Template starting in this month
                overriddenTemplateIds.insert(tx.id)
                let isDeletedForThisMonth = tx.deletedMonths.contains(targetMonthKey)
                let isEndedBeforeThisMonth = tx.endDate.map { calendar.startOfDay(for: $0) < startOfMonth } ?? false
                if !isDeletedForThisMonth && !isEndedBeforeThisMonth {
                    results.append(tx)
                }
            } else {
                results.append(tx)
            }
        }

        // 3. Generate virtual occurrences for active recurring templates
        for template in allTransactions where template.isFixed && template.recurringGroupId == nil {
            let startsBeforeOrDuring = calendar.startOfDay(for: template.date) <= endOfMonth
            let endsAfterOrDuring = template.endDate.map { calendar.startOfDay(for: $0) >= startOfMonth } ?? true

            guard startsBeforeOrDuring,
                  endsAfterOrDuring,
                  !template.deletedMonths.contains(targetMonthKey),
                  !overriddenTemplateIds.contains(template.id),
                  let virtualDate = DateUtils.clampedRecurringDate(from: template.date, inMonthOf: monthDate, calendar: calendar) else {
                continue
            }

            let deterministicId = DateUtils.deterministicUUID(from: template.id, monthKey: targetMonthKey)
            let virtualTx = Transaction(
                id: deterministicId,
                title: template.title,
                amountCents: template.amountCents,
                date: virtualDate,
                isPaid: false,
                type: template.type,
                account: template.account,
                targetAccount: template.targetAccount,
                isFixed: true,
                recurringGroupId: template.id,
                recurringMonth: targetMonthKey
            )
            results.append(virtualTx)
        }

        return results.sorted { $0.date > $1.date }
    }

    /// Groups transactions by start-of-day in chronological order.
    public static func groupedByDay(
        _ transactions: [Transaction],
        calendar: Calendar = .current
    ) -> [(date: Date, transactions: [Transaction])] {
        let grouped = Dictionary(grouping: transactions) { tx in
            calendar.startOfDay(for: tx.date)
        }
        return grouped
            .map { (date: $0.key, transactions: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.date < $1.date }
    }

    /// Computes summary metrics for a given month's transactions and current accounts.
    public static func summary(
        for monthTransactions: [Transaction],
        accounts: [Account]
    ) -> MonthSummary {
        let currentBalance = accounts.reduce(0) { $0 + $1.currentBalanceCents }
        var unpaidIncome = 0
        var unpaidExpense = 0
        var monthIncome = 0
        var monthExpense = 0

        for tx in monthTransactions {
            switch tx.type {
            case .income:
                monthIncome += tx.amountCents
                if !tx.isPaid {
                    unpaidIncome += tx.amountCents
                }
            case .expense:
                monthExpense += tx.amountCents
                if !tx.isPaid {
                    unpaidExpense += tx.amountCents
                }
            case .transfer:
                break
            }
        }

        let expectedBalance = currentBalance + unpaidIncome - unpaidExpense
        return MonthSummary(
            currentBalanceCents: currentBalance,
            expectedBalanceCents: expectedBalance,
            monthIncomeCents: monthIncome,
            monthExpenseCents: monthExpense
        )
    }

    /// Toggles the `isPaid` status of a transaction, materializing it first if it is a virtual recurring occurrence.
    public static func togglePaid(_ tx: Transaction, in context: ModelContext) {
        if tx.isVirtual {
            let materialized = Transaction(
                title: tx.title,
                amountCents: tx.amountCents,
                date: tx.date,
                isPaid: !tx.isPaid,
                type: tx.type,
                account: tx.account,
                targetAccount: tx.targetAccount,
                isFixed: true,
                recurringGroupId: tx.recurringGroupId,
                recurringMonth: tx.recurringMonth
            )
            context.insert(materialized)
        } else {
            tx.isPaid.toggle()
        }
    }

    /// Deletes a transaction or recurring occurrence (single or future) in `context`.
    public static func delete(
        _ tx: Transaction,
        deleteFuture: Bool,
        in context: ModelContext,
        calendar: Calendar = .current
    ) {
        let date = tx.date
        let isVirtual = tx.isVirtual
        let targetMonthKey = tx.recurringMonth ?? DateUtils.monthKey(for: date)

        let template: Transaction?
        if let templateId = tx.recurringGroupId {
            let descriptor = FetchDescriptor<Transaction>(predicate: #Predicate { $0.id == templateId })
            template = (try? context.fetch(descriptor))?.first
        } else if tx.isFixed {
            template = tx
        } else {
            template = nil
        }

        if isVirtual {
            guard let template else { return }
            if deleteFuture {
                template.endDate = calendar.date(byAdding: .day, value: -1, to: date)
                let templateId = template.id
                if let overrides = try? context.fetch(FetchDescriptor<Transaction>(predicate: #Predicate { $0.recurringGroupId == templateId })) {
                    for override in overrides where override.date >= date {
                        context.delete(override)
                    }
                }
            } else if !template.deletedMonths.contains(targetMonthKey) {
                template.deletedMonths.append(targetMonthKey)
            }
            return
        }

        if let template {
            if deleteFuture {
                context.delete(tx)
                if template == tx {
                    let templateId = tx.id
                    if let overrides = try? context.fetch(FetchDescriptor<Transaction>(predicate: #Predicate { $0.recurringGroupId == templateId })) {
                        for override in overrides {
                            context.delete(override)
                        }
                    }
                } else {
                    template.endDate = calendar.date(byAdding: .day, value: -1, to: date)
                    let templateId = template.id
                    if let overrides = try? context.fetch(FetchDescriptor<Transaction>(predicate: #Predicate { $0.recurringGroupId == templateId })) {
                        for override in overrides where override.date >= date && override.id != tx.id {
                            context.delete(override)
                        }
                    }
                }
            } else {
                if template == tx {
                    // Deleting only the template's first occurrence: mark month as deleted
                    if !template.deletedMonths.contains(targetMonthKey) {
                        template.deletedMonths.append(targetMonthKey)
                    }
                } else {
                    // Deleting a materialized override
                    context.delete(tx)
                    if !template.deletedMonths.contains(targetMonthKey) {
                        template.deletedMonths.append(targetMonthKey)
                    }
                }
            }
        } else {
            context.delete(tx)
        }
    }

    /// Creates a new transaction or updates a non-recurring transaction.
    public static func saveNewOrNonRecurring(
        draft: TransactionDraft,
        editing transactionToEdit: Transaction?,
        in context: ModelContext
    ) {
        if let tx = transactionToEdit {
            tx.title = draft.title
            tx.amountCents = draft.amountCents
            tx.date = draft.date
            tx.isPaid = draft.isPaid
            tx.type = draft.type
            tx.account = draft.account
            tx.targetAccount = draft.targetAccount
            if draft.isFixed {
                tx.isFixed = true
                tx.recurringGroupId = nil
            }
        } else {
            let newTx = Transaction(
                title: draft.title,
                amountCents: draft.amountCents,
                date: draft.date,
                isPaid: draft.isPaid,
                type: draft.type,
                account: draft.account,
                targetAccount: draft.targetAccount,
                isFixed: draft.isFixed,
                recurringGroupId: nil
            )
            context.insert(newTx)
        }
    }

    /// Saves changes to a single occurrence of a recurring transaction.
    public static func saveRecurringOverride(
        draft: TransactionDraft,
        for tx: Transaction,
        in context: ModelContext
    ) {
        let monthKey = tx.recurringMonth ?? DateUtils.monthKey(for: tx.date)

        if tx.isVirtual {
            let overrideTx = Transaction(
                title: draft.title,
                amountCents: draft.amountCents,
                date: draft.date,
                isPaid: draft.isPaid,
                type: draft.type,
                account: draft.account,
                targetAccount: draft.targetAccount,
                isFixed: draft.isFixed,
                recurringGroupId: tx.recurringGroupId,
                recurringMonth: monthKey
            )
            context.insert(overrideTx)
        } else if tx.recurringGroupId == nil {
            if !tx.deletedMonths.contains(monthKey) {
                tx.deletedMonths.append(monthKey)
            }
            let overrideTx = Transaction(
                title: draft.title,
                amountCents: draft.amountCents,
                date: draft.date,
                isPaid: draft.isPaid,
                type: draft.type,
                account: draft.account,
                targetAccount: draft.targetAccount,
                isFixed: draft.isFixed,
                recurringGroupId: tx.id,
                recurringMonth: monthKey
            )
            context.insert(overrideTx)
        } else {
            tx.title = draft.title
            tx.amountCents = draft.amountCents
            tx.date = draft.date
            tx.isPaid = draft.isPaid
            tx.type = draft.type
            tx.account = draft.account
            tx.targetAccount = draft.targetAccount
            tx.isFixed = draft.isFixed
        }
    }

    /// Saves changes to a recurring transaction and all future occurrences.
    public static func saveRecurringFuture(
        draft: TransactionDraft,
        for tx: Transaction,
        in context: ModelContext,
        calendar: Calendar = .current
    ) {
        let templateId = tx.recurringGroupId ?? tx.id
        let descriptor = FetchDescriptor<Transaction>(predicate: #Predicate { $0.id == templateId })
        if let template = (try? context.fetch(descriptor))?.first {
            template.endDate = calendar.date(byAdding: .day, value: -1, to: tx.date)
        }

        let replacementTx = Transaction(
            title: draft.title,
            amountCents: draft.amountCents,
            date: draft.date,
            isPaid: draft.isPaid,
            type: draft.type,
            account: draft.account,
            targetAccount: draft.targetAccount,
            isFixed: draft.isFixed,
            recurringGroupId: nil
        )
        context.insert(replacementTx)

        if let overrides = try? context.fetch(FetchDescriptor<Transaction>(predicate: #Predicate { $0.recurringGroupId == templateId })) {
            for override in overrides where override.date >= tx.date {
                context.delete(override)
            }
        }

        if !tx.isVirtual && tx.id != templateId {
            context.delete(tx)
        }
    }
}
