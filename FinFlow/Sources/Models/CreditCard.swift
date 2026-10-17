import Foundation
import SwiftData

@Model
public final class CreditCard {
    public var id: UUID
    public var name: String
    public var limitCents: Int
    public var closingDay: Int
    public var dueDay: Int
    public var iconSystemName: String
    public var colorHex: String

    @Relationship(deleteRule: .cascade)
    public var transactions: [Transaction]? = []

    @Relationship(inverse: \Account.linkedCreditCards)
    public var paymentAccount: Account?

    public init(
        id: UUID = UUID(),
        name: String,
        limitCents: Int,
        closingDay: Int = 5,
        dueDay: Int = 12,
        iconSystemName: String = "creditcard.fill",
        colorHex: String = "#1A5CFF",
        paymentAccount: Account? = nil
    ) {
        self.id = id
        self.name = name
        self.limitCents = limitCents
        self.closingDay = min(max(closingDay, 1), 31)
        self.dueDay = min(max(dueDay, 1), 31)
        self.iconSystemName = iconSystemName
        self.colorHex = colorHex
        self.paymentAccount = paymentAccount
    }
}
