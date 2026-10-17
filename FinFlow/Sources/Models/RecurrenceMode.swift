import Foundation

public enum RecurrenceMode: String, CaseIterable, Identifiable, Sendable {
    case single
    case installment
    case fixed

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .single: "Único"
        case .installment: "Parcelado"
        case .fixed: "Fixo"
        }
    }

    public var iconSystemName: String {
        switch self {
        case .single: "1.circle.fill"
        case .installment: "square.stack.3d.up.fill"
        case .fixed: "repeat.circle.fill"
        }
    }
}
