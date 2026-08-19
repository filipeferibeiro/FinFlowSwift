import Foundation
import SwiftData
public enum TransactionType: Codable, Equatable, Sendable {
    case income
    case expense
    case transfer
    
    nonisolated public static func ==(lhs: TransactionType, rhs: TransactionType) -> Bool {
        switch (lhs, rhs) {
        case (.income, .income): return true
        case (.expense, .expense): return true
        case (.transfer, .transfer): return true
        default: return false
        }
    }
}


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
    public var targetAccount: Account? // Only for transfers
    
    public init(id: UUID = UUID(), title: String, amountCents: Int, date: Date, isPaid: Bool, type: TransactionType, account: Account? = nil, targetAccount: Account? = nil) {
        self.id = id
        self.title = title
        self.amountCents = amountCents
        self.date = date
        self.isPaid = isPaid
        self.type = type
        self.account = account
        self.targetAccount = targetAccount
    }
}
