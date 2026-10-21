import Foundation
import SwiftData

@Model
public final class Account {
    public var id: UUID
    public var name: String
    public var initialBalanceCents: Int
    public var iconSystemName: String
    public var colorHex: String

    @Relationship(deleteRule: .cascade)
    public var transactions: [Transaction]? = []

    @Relationship(deleteRule: .cascade)
    public var incomingTransfers: [Transaction]? = []

    @Relationship(deleteRule: .nullify)
    public var linkedCreditCards: [CreditCard]? = []

    public init(
        id: UUID = UUID(),
        name: String,
        initialBalanceCents: Int,
        iconSystemName: String = "building.columns.fill",
        colorHex: String = "#1A5CFF"
    ) {
        self.id = id
        self.name = name
        self.initialBalanceCents = initialBalanceCents
        self.iconSystemName = iconSystemName
        self.colorHex = colorHex
    }

    @Transient public var currentBalanceCents: Int {
        var balance = initialBalanceCents

        for tx in (transactions ?? []) where tx.isPaid && tx.isActiveMaterializedOccurrence {
            switch tx.type {
            case .expense, .transfer:
                balance -= tx.amountCents
            case .income:
                balance += tx.amountCents
            }
        }

        for tx in (incomingTransfers ?? []) where tx.isPaid && tx.type == .transfer && tx.isActiveMaterializedOccurrence {
            balance += tx.amountCents
        }

        return balance
    }
}
