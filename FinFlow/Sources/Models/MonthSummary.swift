import Foundation

public struct MonthSummary: Equatable, Sendable {
    public let currentBalanceCents: Int
    public let expectedBalanceCents: Int
    public let monthIncomeCents: Int
    public let monthExpenseCents: Int

    public init(
        currentBalanceCents: Int,
        expectedBalanceCents: Int,
        monthIncomeCents: Int,
        monthExpenseCents: Int
    ) {
        self.currentBalanceCents = currentBalanceCents
        self.expectedBalanceCents = expectedBalanceCents
        self.monthIncomeCents = monthIncomeCents
        self.monthExpenseCents = monthExpenseCents
    }
}
