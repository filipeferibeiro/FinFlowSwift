import Foundation

public enum TransactionFilter: String, CaseIterable, Identifiable, Sendable {
    case all
    case income
    case expense
    case pending

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .all: "Todas"
        case .income: "Entradas"
        case .expense: "Saídas"
        case .pending: "Pendentes"
        }
    }

    public func matches(_ transaction: Transaction) -> Bool {
        switch self {
        case .all:
            true
        case .income:
            transaction.type == .income
        case .expense:
            transaction.type == .expense
        case .pending:
            !transaction.isPaid
        }
    }
}
