import Foundation

public struct TransactionDraft {
    public var title: String
    public var amountCents: Int
    public var date: Date
    public var isPaid: Bool
    public var type: TransactionType
    public var isFixed: Bool
    public var account: Account?
    public var targetAccount: Account?

    public init(
        title: String,
        amountCents: Int,
        date: Date,
        isPaid: Bool,
        type: TransactionType,
        isFixed: Bool,
        account: Account?,
        targetAccount: Account?
    ) {
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.amountCents = amountCents
        self.date = date
        self.isPaid = isPaid
        self.type = type
        self.isFixed = isFixed
        self.account = account
        self.targetAccount = type == .transfer ? targetAccount : nil
    }
}
