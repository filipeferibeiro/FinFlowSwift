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

    public var isFixed: Bool = false
    public var recurringGroupId: UUID?
    public var recurringMonth: String?
    public var endDate: Date?
    public var deletedMonths: [String] = []

    public init(
        id: UUID = UUID(),
        title: String,
        amountCents: Int,
        date: Date,
        isPaid: Bool,
        type: TransactionType,
        account: Account? = nil,
        targetAccount: Account? = nil,
        isFixed: Bool = false,
        recurringGroupId: UUID? = nil,
        recurringMonth: String? = nil,
        endDate: Date? = nil,
        deletedMonths: [String] = []
    ) {
        self.id = id
        self.title = title
        self.amountCents = amountCents
        self.date = date
        self.isPaid = isPaid
        self.type = type
        self.account = account
        self.targetAccount = targetAccount
        self.isFixed = isFixed
        self.recurringGroupId = recurringGroupId
        self.recurringMonth = recurringMonth
        self.endDate = endDate
        self.deletedMonths = deletedMonths
    }

    @Transient
    public var isVirtual: Bool {
        modelContext == nil
    }

    @Transient
    public var accountDisplayTitle: String {
        let originName = account?.name ?? "Sem Conta"
        if type == .transfer, let targetName = targetAccount?.name {
            return "\(originName) → \(targetName)"
        }
        return originName
    }
}
