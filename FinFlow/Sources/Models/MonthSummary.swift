import Foundation

public struct MonthSummary: Equatable, Sendable {
    public let currentBalanceCents: Int
    public let expectedBalanceCents: Int
    public let monthIncomeCents: Int
    public let monthExpenseCents: Int
    public let creditCardInvoicesCents: Int

    public init(
        currentBalanceCents: Int,
        expectedBalanceCents: Int,
        monthIncomeCents: Int,
        monthExpenseCents: Int,
        creditCardInvoicesCents: Int = 0
    ) {
        self.currentBalanceCents = currentBalanceCents
        self.expectedBalanceCents = expectedBalanceCents
        self.monthIncomeCents = monthIncomeCents
        self.monthExpenseCents = monthExpenseCents
        self.creditCardInvoicesCents = creditCardInvoicesCents
    }
}
