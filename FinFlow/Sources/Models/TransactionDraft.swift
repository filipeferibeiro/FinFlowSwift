import Foundation

public struct TransactionDraft {
    public var title: String
    public var amountCents: Int
    public var date: Date
    public var isPaid: Bool
    public var type: TransactionType
    public var recurrenceMode: RecurrenceMode
    public var totalInstallments: Int
    public var divideAmountAcrossInstallments: Bool
    public var account: Account?
    public var targetAccount: Account?
    public var creditCard: CreditCard?

    public var isFixed: Bool {
        recurrenceMode == .fixed
    }

    public init(
        title: String,
        amountCents: Int,
        date: Date,
        isPaid: Bool,
        type: TransactionType,
        recurrenceMode: RecurrenceMode = .single,
        totalInstallments: Int = 2,
        divideAmountAcrossInstallments: Bool = true,
        account: Account? = nil,
        targetAccount: Account? = nil,
        creditCard: CreditCard? = nil
    ) {
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.amountCents = amountCents
        self.date = date
        self.isPaid = isPaid
        self.type = type
        self.recurrenceMode = recurrenceMode
        self.totalInstallments = max(2, totalInstallments)
        self.divideAmountAcrossInstallments = divideAmountAcrossInstallments
        self.account = creditCard == nil ? account : nil
        self.targetAccount = (type == .transfer && creditCard == nil) ? targetAccount : nil
        self.creditCard = type == .expense ? creditCard : nil
    }
}
