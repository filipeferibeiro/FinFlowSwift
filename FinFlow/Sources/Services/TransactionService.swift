import Foundation
import SwiftData

public enum TransactionService {
    /// Computes the active list of materialized + virtual recurring ACCOUNT transactions AND credit card invoice due-date records for `monthDate`.
    public static func transactions(
        for monthDate: Date,
        from allTransactions: [Transaction],
        creditCards: [CreditCard] = [],
        accounts: [Account] = [],
        calendar: Calendar = .current
    ) -> [Transaction] {
        let accountOnly = allTransactions.filter { $0.creditCard == nil && $0.invoiceCreditCardId == nil }
        var results = resolveMonthlyTransactions(for: monthDate, from: accountOnly, calendar: calendar)

        let targetMonthKey = DateUtils.monthKey(for: monthDate)

        for card in creditCards {
            let invoiceSummary = creditCardInvoiceSummary(
                for: card,
                in: monthDate,
                from: allTransactions,
                calendar: calendar
            )
            guard invoiceSummary.totalCents > 0 else { continue }

            let dueDate = DateUtils.date(forDay: card.dueDay, inMonthOf: monthDate, calendar: calendar) ?? monthDate

            if let persistedInvoice = allTransactions.first(where: {
                $0.invoiceCreditCardId == card.id && $0.invoiceMonthKey == targetMonthKey
            }) {
                results.append(persistedInvoice)
            } else {
                let deterministicId = DateUtils.deterministicUUID(from: card.id, monthKey: "INVOICE-\(targetMonthKey)")
                let defaultAccount = card.paymentAccount ?? accounts.first
                let virtualInvoiceTx = Transaction(
                    id: deterministicId,
                    title: "Fatura \(card.name)",
                    amountCents: invoiceSummary.totalCents,
                    date: dueDate,
                    isPaid: invoiceSummary.isFullyPaid,
                    type: .expense,
                    account: defaultAccount,
                    invoiceCreditCardId: card.id,
                    invoiceMonthKey: targetMonthKey
                )
                results.append(virtualInvoiceTx)
            }
        }

        return results.sorted { $0.date > $1.date }
    }

    /// Computes the active list of materialized + virtual recurring CREDIT CARD transactions for a specific `card` and `monthDate`.
    public static func creditCardTransactions(
        for card: CreditCard,
        in monthDate: Date,
        from allTransactions: [Transaction],
        calendar: Calendar = .current
    ) -> [Transaction] {
        let cardOnly = allTransactions.filter { $0.creditCard?.id == card.id }
        return resolveMonthlyTransactions(for: monthDate, from: cardOnly, calendar: calendar)
    }

    /// Internal resolver for monthly materialized + virtual recurring transactions.
    private static func resolveMonthlyTransactions(
        for monthDate: Date,
        from sourceTransactions: [Transaction],
        calendar: Calendar = .current
    ) -> [Transaction] {
        guard let (startOfMonth, endOfMonth) = DateUtils.monthBounds(for: monthDate, calendar: calendar) else {
            return []
        }

        let targetMonthKey = DateUtils.monthKey(for: monthDate)
        var results: [Transaction] = []
        var overriddenTemplateIds = Set<UUID>()

        // 1. Register all template overrides targeting this month (even if their date was moved)
        for tx in sourceTransactions {
            if let templateId = tx.recurringGroupId {
                if tx.recurringMonth == targetMonthKey || calendar.isDate(tx.date, equalTo: monthDate, toGranularity: .month) {
                    overriddenTemplateIds.insert(templateId)
                }
            }
        }

        // 2. Collect materialized transactions falling in this month
        for tx in sourceTransactions {
            guard calendar.isDate(tx.date, equalTo: monthDate, toGranularity: .month) else { continue }

            if tx.isFixed && tx.recurringGroupId == nil {
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
        for template in sourceTransactions where template.isFixed && template.recurringGroupId == nil {
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
                creditCard: template.creditCard,
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

    /// Computes summary metrics for a given month's statement transactions (which already include credit card invoice records).
    public static func summary(
        for monthTransactions: [Transaction],
        accounts: [Account]
    ) -> MonthSummary {
        let currentBalance = accounts.reduce(0) { $0 + $1.currentBalanceCents }
        var unpaidIncome = 0
        var unpaidExpense = 0
        var monthIncome = 0
        var monthExpense = 0
        var creditCardInvoices = 0

        for tx in monthTransactions {
            switch tx.type {
            case .income:
                monthIncome += tx.amountCents
                if !tx.isPaid {
                    unpaidIncome += tx.amountCents
                }
            case .expense:
                monthExpense += tx.amountCents
                if tx.isCreditCardInvoice {
                    creditCardInvoices += tx.amountCents
                }
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
            monthExpenseCents: monthExpense,
            creditCardInvoicesCents: creditCardInvoices
        )
    }

    /// Computes a credit card's invoice summary for `monthDate`.
    public static func creditCardInvoiceSummary(
        for card: CreditCard,
        in monthDate: Date,
        from allTransactions: [Transaction],
        calendar: Calendar = .current
    ) -> (totalCents: Int, unpaidCents: Int, isFullyPaid: Bool, itemCount: Int, paidByAccount: Account?) {
        let targetMonthKey = DateUtils.monthKey(for: monthDate)
        let persistedInvoice = allTransactions.first {
            $0.invoiceCreditCardId == card.id && $0.invoiceMonthKey == targetMonthKey
        }
        let items = creditCardTransactions(for: card, in: monthDate, from: allTransactions, calendar: calendar)
        let total = items.reduce(0) { $0 + $1.amountCents }

        if let persistedInvoice, persistedInvoice.isPaid {
            return (
                totalCents: total,
                unpaidCents: 0,
                isFullyPaid: !items.isEmpty,
                itemCount: items.count,
                paidByAccount: persistedInvoice.account ?? card.paymentAccount
            )
        }

        let unpaid = items.filter { !$0.isPaid }.reduce(0) { $0 + $1.amountCents }
        let isFullyPaid = !items.isEmpty && unpaid == 0
        return (
            totalCents: total,
            unpaidCents: unpaid,
            isFullyPaid: isFullyPaid,
            itemCount: items.count,
            paidByAccount: isFullyPaid ? card.paymentAccount : nil
        )
    }

    /// Computes total used credit limit across all unpaid items on `card`.
    public static func creditCardUsedLimitCents(
        for card: CreditCard,
        from allTransactions: [Transaction],
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> Int {
        let cardTransactions = allTransactions.filter { $0.creditCard?.id == card.id }
        let materializedUnpaid = cardTransactions
            .filter { !$0.isPaid && !($0.isFixed && $0.recurringGroupId == nil) }
            .reduce(0) { $0 + $1.amountCents }

        let currentMonthItems = resolveMonthlyTransactions(for: referenceDate, from: cardTransactions, calendar: calendar)
        let fixedUnpaidThisMonth = currentMonthItems
            .filter { $0.isFixed && !$0.isPaid && ($0.isVirtual || $0.recurringGroupId == nil) }
            .reduce(0) { $0 + $1.amountCents }

        return materializedUnpaid + fixedUnpaidThisMonth
    }

    /// Pays a credit card's monthly invoice using `account`, registering the debit on `account` on the card's due day.
    public static func payCreditCardInvoice(
        for card: CreditCard,
        in monthDate: Date,
        using account: Account,
        from allTransactions: [Transaction],
        in context: ModelContext,
        calendar: Calendar = .current
    ) {
        let items = creditCardTransactions(for: card, in: monthDate, from: allTransactions, calendar: calendar)
        let totalCents = items.reduce(0) { $0 + $1.amountCents }
        guard totalCents > 0 else { return }

        // 1. Mark all items in the invoice as paid
        for item in items where !item.isPaid {
            if item.isVirtual {
                let materialized = Transaction(
                    title: item.title,
                    amountCents: item.amountCents,
                    date: item.date,
                    isPaid: true,
                    type: item.type,
                    creditCard: card,
                    isFixed: true,
                    recurringGroupId: item.recurringGroupId,
                    recurringMonth: item.recurringMonth
                )
                context.insert(materialized)
            } else {
                item.isPaid = true
            }
        }

        // 2. Register or update the persisted debit transaction on `account` at `card.dueDay`
        let targetMonthKey = DateUtils.monthKey(for: monthDate)
        let dueDate = DateUtils.date(forDay: card.dueDay, inMonthOf: monthDate, calendar: calendar) ?? monthDate

        if let existingInvoiceTx = allTransactions.first(where: {
            $0.invoiceCreditCardId == card.id && $0.invoiceMonthKey == targetMonthKey
        }) {
            existingInvoiceTx.title = "Fatura \(card.name)"
            existingInvoiceTx.amountCents = totalCents
            existingInvoiceTx.date = dueDate
            existingInvoiceTx.isPaid = true
            existingInvoiceTx.type = .expense
            existingInvoiceTx.account = account
        } else {
            let invoiceTx = Transaction(
                title: "Fatura \(card.name)",
                amountCents: totalCents,
                date: dueDate,
                isPaid: true,
                type: .expense,
                account: account,
                invoiceCreditCardId: card.id,
                invoiceMonthKey: targetMonthKey
            )
            context.insert(invoiceTx)
        }

        if card.paymentAccount == nil {
            card.paymentAccount = account
        }
    }

    /// Reopens a paid credit card invoice, refunding the debited account and marking the invoice's items as unpaid.
    public static func reopenCreditCardInvoice(
        for card: CreditCard,
        in monthDate: Date,
        from allTransactions: [Transaction],
        in context: ModelContext,
        calendar: Calendar = .current
    ) {
        let items = creditCardTransactions(for: card, in: monthDate, from: allTransactions, calendar: calendar)
        for item in items where item.isPaid {
            if !item.isVirtual {
                item.isPaid = false
            }
        }

        let targetMonthKey = DateUtils.monthKey(for: monthDate)
        let cardId = card.id
        if let invoiceRecords = try? context.fetch(
            FetchDescriptor<Transaction>(predicate: #Predicate {
                $0.invoiceCreditCardId == cardId && $0.invoiceMonthKey == targetMonthKey
            })
        ) {
            for record in invoiceRecords {
                context.delete(record)
            }
        }
    }

    /// Synchronizes any persisted invoice records for `card` when items or card metadata change.
    public static func syncPersistedInvoices(
        for card: CreditCard,
        in context: ModelContext,
        calendar: Calendar = .current
    ) {
        guard let allTransactions = try? context.fetch(FetchDescriptor<Transaction>()) else { return }
        let cardId = card.id
        let invoiceRecords = allTransactions.filter { $0.invoiceCreditCardId == cardId }

        for record in invoiceRecords {
            guard let monthKey = record.invoiceMonthKey else { continue }
            let parts = monthKey.split(separator: "-")
            guard parts.count == 2,
                  let year = Int(parts[0]),
                  let month = Int(parts[1]),
                  let monthDate = calendar.date(from: DateComponents(year: year, month: month, day: 1)) else {
                continue
            }

            let items = creditCardTransactions(for: card, in: monthDate, from: allTransactions, calendar: calendar)
            let newTotal = items.reduce(0) { $0 + $1.amountCents }

            if newTotal <= 0 {
                context.delete(record)
            } else {
                record.title = "Fatura \(card.name)"
                record.amountCents = newTotal
                if let dueDate = DateUtils.date(forDay: card.dueDay, inMonthOf: monthDate, calendar: calendar) {
                    record.date = dueDate
                }
                if record.isPaid {
                    for item in items where !item.isPaid && !item.isVirtual {
                        item.isPaid = true
                    }
                }
            }
        }
    }

    /// Deletes all persisted invoice payment transactions linked to `card`.
    public static func deletePersistedInvoices(for card: CreditCard, in context: ModelContext) {
        let cardId = card.id
        if let invoiceRecords = try? context.fetch(
            FetchDescriptor<Transaction>(predicate: #Predicate { $0.invoiceCreditCardId == cardId })
        ) {
            for record in invoiceRecords {
                context.delete(record)
            }
        }
    }

    /// Toggles the `isPaid` status of a normal account transaction, materializing it first if it is a virtual recurring occurrence.
    public static func togglePaid(_ tx: Transaction, in context: ModelContext) {
        guard !tx.isCreditCardInvoice else { return }

        if tx.isVirtual {
            let materialized = Transaction(
                title: tx.title,
                amountCents: tx.amountCents,
                date: tx.date,
                isPaid: !tx.isPaid,
                type: tx.type,
                account: tx.account,
                targetAccount: tx.targetAccount,
                creditCard: tx.creditCard,
                isFixed: true,
                recurringGroupId: tx.recurringGroupId,
                recurringMonth: tx.recurringMonth
            )
            context.insert(materialized)
        } else {
            tx.isPaid.toggle()
        }
    }

    /// Deletes a transaction, installment, or recurring occurrence (single or future) in `context`.
    public static func delete(
        _ tx: Transaction,
        deleteFuture: Bool,
        in context: ModelContext,
        calendar: Calendar = .current
    ) {
        let affectedCard = tx.creditCard

        // 1. Handle Installment Group deletion
        if let groupId = tx.installmentGroupId {
            if deleteFuture {
                let currentIdx = tx.installmentIndex ?? 1
                let txDate = tx.date
                if let siblings = try? context.fetch(FetchDescriptor<Transaction>(predicate: #Predicate { $0.installmentGroupId == groupId })) {
                    for item in siblings {
                        let itemIdx = item.installmentIndex ?? 1
                        if itemIdx >= currentIdx || item.date >= txDate {
                            context.delete(item)
                        }
                    }
                }
            } else {
                context.delete(tx)
            }
            if let affectedCard {
                syncPersistedInvoices(for: affectedCard, in: context, calendar: calendar)
            }
            return
        }

        // 2. Handle Fixed Recurring or Single deletion
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
            if let affectedCard {
                syncPersistedInvoices(for: affectedCard, in: context, calendar: calendar)
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
                    if !template.deletedMonths.contains(targetMonthKey) {
                        template.deletedMonths.append(targetMonthKey)
                    }
                } else {
                    context.delete(tx)
                    if !template.deletedMonths.contains(targetMonthKey) {
                        template.deletedMonths.append(targetMonthKey)
                    }
                }
            }
        } else {
            context.delete(tx)
        }

        if let affectedCard {
            syncPersistedInvoices(for: affectedCard, in: context, calendar: calendar)
        }
    }

    /// Creates a new transaction (single, installment series, or fixed recurring) or updates a non-recurring transaction.
    public static func saveNewOrNonRecurring(
        draft: TransactionDraft,
        editing transactionToEdit: Transaction?,
        in context: ModelContext,
        calendar: Calendar = .current
    ) {
        if let tx = transactionToEdit {
            let previousCard = tx.creditCard
            tx.title = draft.title
            tx.amountCents = draft.amountCents
            tx.date = draft.date
            tx.isPaid = draft.isPaid
            tx.type = draft.type
            tx.account = draft.account
            tx.targetAccount = draft.targetAccount
            tx.creditCard = draft.creditCard
            if draft.isFixed {
                tx.isFixed = true
                tx.recurringGroupId = nil
                tx.installmentGroupId = nil
                tx.installmentIndex = nil
                tx.totalInstallments = nil
            }
            if let previousCard {
                syncPersistedInvoices(for: previousCard, in: context, calendar: calendar)
            }
            if let newCard = draft.creditCard {
                syncPersistedInvoices(for: newCard, in: context, calendar: calendar)
            }
            return
        }

        switch draft.recurrenceMode {
        case .single:
            let newTx = Transaction(
                title: draft.title,
                amountCents: draft.amountCents,
                date: draft.date,
                isPaid: draft.isPaid,
                type: draft.type,
                account: draft.account,
                targetAccount: draft.targetAccount,
                creditCard: draft.creditCard,
                isFixed: false
            )
            context.insert(newTx)

        case .fixed:
            let newTx = Transaction(
                title: draft.title,
                amountCents: draft.amountCents,
                date: draft.date,
                isPaid: draft.isPaid,
                type: draft.type,
                account: draft.account,
                targetAccount: draft.targetAccount,
                creditCard: draft.creditCard,
                isFixed: true
            )
            context.insert(newTx)

        case .installment:
            let count = max(2, draft.totalInstallments)
            let groupId = UUID()
            let baseAmount = draft.divideAmountAcrossInstallments ? (draft.amountCents / count) : draft.amountCents
            let remainder = draft.divideAmountAcrossInstallments ? (draft.amountCents % count) : 0

            for offset in 0..<count {
                guard let targetMonth = calendar.date(byAdding: .month, value: offset, to: draft.date),
                      let installmentDate = DateUtils.clampedRecurringDate(from: draft.date, inMonthOf: targetMonth, calendar: calendar) else {
                    continue
                }

                let itemAmount = offset == 0 ? (baseAmount + remainder) : baseAmount
                let itemIsPaid = draft.creditCard != nil ? false : (offset == 0 ? draft.isPaid : false)

                let installmentTx = Transaction(
                    title: draft.title,
                    amountCents: max(1, itemAmount),
                    date: installmentDate,
                    isPaid: itemIsPaid,
                    type: draft.type,
                    account: draft.account,
                    targetAccount: draft.targetAccount,
                    creditCard: draft.creditCard,
                    isFixed: false,
                    installmentGroupId: groupId,
                    installmentIndex: offset + 1,
                    totalInstallments: count
                )
                context.insert(installmentTx)
            }
        }

        if let card = draft.creditCard {
            syncPersistedInvoices(for: card, in: context, calendar: calendar)
        }
    }

    /// Saves changes to a single occurrence of a recurring or installment transaction.
    public static func saveRecurringOverride(
        draft: TransactionDraft,
        for tx: Transaction,
        in context: ModelContext,
        calendar: Calendar = .current
    ) {
        let previousCard = tx.creditCard

        if tx.isInstallment {
            tx.title = draft.title
            tx.amountCents = draft.amountCents
            tx.date = draft.date
            tx.isPaid = draft.isPaid
            tx.type = draft.type
            tx.account = draft.account
            tx.targetAccount = draft.targetAccount
            tx.creditCard = draft.creditCard
            if let previousCard {
                syncPersistedInvoices(for: previousCard, in: context, calendar: calendar)
            }
            if let newCard = draft.creditCard {
                syncPersistedInvoices(for: newCard, in: context, calendar: calendar)
            }
            return
        }

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
                creditCard: draft.creditCard,
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
                creditCard: draft.creditCard,
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
            tx.creditCard = draft.creditCard
            tx.isFixed = draft.isFixed
        }

        if let previousCard {
            syncPersistedInvoices(for: previousCard, in: context, calendar: calendar)
        }
        if let newCard = draft.creditCard {
            syncPersistedInvoices(for: newCard, in: context, calendar: calendar)
        }
    }

    /// Saves changes to a recurring/installment transaction and all future occurrences.
    public static func saveRecurringFuture(
        draft: TransactionDraft,
        for tx: Transaction,
        in context: ModelContext,
        calendar: Calendar = .current
    ) {
        let previousCard = tx.creditCard

        if let groupId = tx.installmentGroupId {
            let currentIdx = tx.installmentIndex ?? 1
            tx.date = draft.date
            tx.isPaid = draft.isPaid
            if let siblings = try? context.fetch(FetchDescriptor<Transaction>(predicate: #Predicate { $0.installmentGroupId == groupId })) {
                for item in siblings where (item.installmentIndex ?? 1) >= currentIdx {
                    item.title = draft.title
                    item.amountCents = draft.amountCents
                    item.type = draft.type
                    item.account = draft.account
                    item.targetAccount = draft.targetAccount
                    item.creditCard = draft.creditCard
                }
            }
            if let previousCard {
                syncPersistedInvoices(for: previousCard, in: context, calendar: calendar)
            }
            if let newCard = draft.creditCard {
                syncPersistedInvoices(for: newCard, in: context, calendar: calendar)
            }
            return
        }

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
            creditCard: draft.creditCard,
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

        if let previousCard {
            syncPersistedInvoices(for: previousCard, in: context, calendar: calendar)
        }
        if let newCard = draft.creditCard {
            syncPersistedInvoices(for: newCard, in: context, calendar: calendar)
        }
    }
}
