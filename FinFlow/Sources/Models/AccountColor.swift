import Foundation

public struct AccountColor: Identifiable, Hashable, Sendable {
    public var id: String { hex }
    public let name: String
    public let hex: String

    public init(name: String, hex: String) {
        self.name = name
        self.hex = hex
    }

    public static let presets: [AccountColor] = [
        AccountColor(name: "Azul Royal", hex: "#1A5CFF"),
        AccountColor(name: "Safira", hex: "#007AFF"),
        AccountColor(name: "Ciano Oceano", hex: "#0096E6"),
        AccountColor(name: "Esmeralda", hex: "#059669"),
        AccountColor(name: "Índigo", hex: "#4F46E5"),
        AccountColor(name: "Violeta", hex: "#7C3AED"),
        AccountColor(name: "Rubi", hex: "#E11D48"),
        AccountColor(name: "Carmim", hex: "#DC2626"),
        AccountColor(name: "Âmbar", hex: "#D97706"),
        AccountColor(name: "Grafite", hex: "#334155"),
        AccountColor(name: "Ardósia", hex: "#64748B"),
        AccountColor(name: "Ônix", hex: "#0F172A")
    ]

    public static let financeIcons: [String] = [
        "building.columns.fill", "creditcard.fill", "wallet.pass.fill", "dollarsign.circle.fill",
        "chart.line.uptrend.xyaxis", "chart.pie.fill", "briefcase.fill", "banknote.fill", "lock.shield.fill",
        "bitcoinsign.circle.fill", "centsign.circle.fill", "sterlingsign.circle.fill",
        "yensign.circle.fill", "bag.fill", "cart.fill", "airplane", "car.fill",
        "house.fill", "display", "macbook", "iphone", "gamecontroller.fill",
        "graduationcap.fill", "book.fill", "fork.knife", "cup.and.saucer.fill",
        "pills.fill", "cross.case.fill", "gift.fill", "star.fill", "bolt.fill"
    ]
}
