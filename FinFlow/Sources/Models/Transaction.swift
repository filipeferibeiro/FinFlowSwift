import Foundation
import SwiftData

@Model
public final class Transaction {
    public var id: UUID
    public var title: String
    public var amountCents: Int
    public var date: Date
    public var isPaid: Bool
    public var type: TransactionType

    @Relationship(inverse: \Account.transactions)
    public var account: Account?

    @Relationship(inverse: \Account.incomingTransfers)
    public var targetAccount: Account?

    @Relationship(inverse: \CreditCard.transactions)
    public var creditCard: CreditCard?

    public var isFixed: Bool = false
    public var recurringGroupId: UUID?
    public var recurringMonth: String?
    public var endDate: Date?
    public var deletedMonths: [String] = []

    // Installment support (for both normal account items and credit card items)
    public var installmentGroupId: UUID?
    public var installmentIndex: Int?
    public var totalInstallments: Int?

    // Credit Card Monthly Invoice Statement Record (links an Account debit to a CreditCard monthly invoice)
    public var invoiceCreditCardId: UUID?
    public var invoiceMonthKey: String?

    public init(
        id: UUID = UUID(),
        title: String,
        amountCents: Int,
        date: Date,
        isPaid: Bool,
        type: TransactionType,
        account: Account? = nil,
        targetAccount: Account? = nil,
        creditCard: CreditCard? = nil,
        isFixed: Bool = false,
        recurringGroupId: UUID? = nil,
        recurringMonth: String? = nil,
        endDate: Date? = nil,
        deletedMonths: [String] = [],
        installmentGroupId: UUID? = nil,
        installmentIndex: Int? = nil,
        totalInstallments: Int? = nil,
        invoiceCreditCardId: UUID? = nil,
        invoiceMonthKey: String? = nil
    ) {
        self.id = id
        self.title = title
        self.amountCents = amountCents
        self.date = date
        self.isPaid = isPaid
        self.type = type
        self.account = account
        self.targetAccount = targetAccount
        self.creditCard = creditCard
        self.isFixed = isFixed
        self.recurringGroupId = recurringGroupId
        self.recurringMonth = recurringMonth
        self.endDate = endDate
        self.deletedMonths = deletedMonths
        self.installmentGroupId = installmentGroupId
        self.installmentIndex = installmentIndex
        self.totalInstallments = totalInstallments
        self.invoiceCreditCardId = invoiceCreditCardId
        self.invoiceMonthKey = invoiceMonthKey
    }

    @Transient
    public var isVirtual: Bool {
        modelContext == nil
    }

    @Transient
    public var isInstallment: Bool {
        if let totalInstallments, totalInstallments > 1 {
            return true
        }
        return false
    }

    @Transient
    public var isCreditCardInvoice: Bool {
        invoiceCreditCardId != nil
    }

    @Transient
    public var installmentBadgeText: String? {
        guard let index = installmentIndex, let total = totalInstallments, total > 1 else {
            return nil
        }
        return "\(index)/\(total)"
    }

    @Transient
    public var isRecurringOrInstallment: Bool {
        isFixed || isInstallment
    }

    @Transient
    public var isActiveMaterializedOccurrence: Bool {
        if isFixed && recurringGroupId == nil {
            let ownMonthKey = DateUtils.monthKey(for: date)
            if deletedMonths.contains(ownMonthKey) {
                return false
            }
            if let endDate, Calendar.current.startOfDay(for: endDate) < Calendar.current.startOfDay(for: date) {
                return false
            }
        }
        return true
    }

    @Transient
    public var accountDisplayTitle: String {
        if isCreditCardInvoice {
            let dueDay = Calendar.current.component(.day, from: date)
            if let accountName = account?.name {
                return isPaid ? "Débito em \(accountName)" : "Vence dia \(dueDay) • \(accountName)"
            }
            return "Vence dia \(dueDay) • Selecionar conta"
        }
        if let creditCard {
            return creditCard.name
        }
        let originName = account?.name ?? "Sem Conta"
        if type == .transfer, let targetName = targetAccount?.name {
            return "\(originName) → \(targetName)"
        }
        return originName
    }
}
