import Foundation

public struct MonthSummary: Equatable, Sendable {
    public let previousBalanceCents: Int
    public let currentBalanceCents: Int
    public let expectedBalanceCents: Int
    public let monthIncomeCents: Int
    public let paidIncomeCents: Int
    public let unpaidIncomeCents: Int
    public let monthExpenseCents: Int
    public let paidExpenseCents: Int
    public let unpaidExpenseCents: Int
    public let creditCardInvoicesCents: Int

    public var monthBalanceCents: Int {
        monthIncomeCents - monthExpenseCents
    }

    public init(
        previousBalanceCents: Int = 0,
        currentBalanceCents: Int,
        expectedBalanceCents: Int,
        monthIncomeCents: Int,
        paidIncomeCents: Int = 0,
        unpaidIncomeCents: Int = 0,
        monthExpenseCents: Int,
        paidExpenseCents: Int = 0,
        unpaidExpenseCents: Int = 0,
        creditCardInvoicesCents: Int = 0
    ) {
        self.previousBalanceCents = previousBalanceCents
        self.currentBalanceCents = currentBalanceCents
        self.expectedBalanceCents = expectedBalanceCents
        self.monthIncomeCents = monthIncomeCents
        self.paidIncomeCents = paidIncomeCents
        self.unpaidIncomeCents = unpaidIncomeCents
        self.monthExpenseCents = monthExpenseCents
        self.paidExpenseCents = paidExpenseCents
        self.unpaidExpenseCents = unpaidExpenseCents
        self.creditCardInvoicesCents = creditCardInvoicesCents
    }
}
