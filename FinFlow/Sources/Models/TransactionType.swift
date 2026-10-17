import SwiftUI

public nonisolated enum TransactionType: String, Codable, CaseIterable, Identifiable, Sendable {
    case expense
    case income
    case transfer

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .income: "Receita"
        case .expense: "Despesa"
        case .transfer: "Transferência"
        }
    }

    public var iconSystemName: String {
        switch self {
        case .income: "arrow.down.left"
        case .expense: "arrow.up.right"
        case .transfer: "arrow.left.arrow.right"
        }
    }

    @MainActor
    public var color: Color {
        switch self {
        case .income: Theme.Colors.success
        case .expense: Theme.Colors.error
        case .transfer: Theme.Colors.primary
        }
    }
}
