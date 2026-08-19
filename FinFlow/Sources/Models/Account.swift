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
    
    public init(id: UUID = UUID(), name: String, initialBalanceCents: Int, iconSystemName: String = "building.columns.fill", colorHex: String = "#FF6B00") {
        self.id = id
        self.name = name
        self.initialBalanceCents = initialBalanceCents
        self.iconSystemName = iconSystemName
        self.colorHex = colorHex
    }
    
    @Transient public var currentBalanceCents: Int {
        var balance = initialBalanceCents
        
        for tx in (transactions ?? []) where tx.isPaid {
            if tx.type == .expense {
                balance -= tx.amountCents
            } else if tx.type == .income {
                balance += tx.amountCents
            } else if tx.type == .transfer {
                balance -= tx.amountCents
            }
        }
        
        for tx in (incomingTransfers ?? []) where tx.isPaid && tx.type == .transfer {
            balance += tx.amountCents
        }
        
        return balance
    }
}
