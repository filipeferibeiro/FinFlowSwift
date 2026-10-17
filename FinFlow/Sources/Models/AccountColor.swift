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
        AccountColor(name: "Laranja", hex: "#FF6B00"),
        AccountColor(name: "Amarelo", hex: "#FFCC00"),
        AccountColor(name: "Verde", hex: "#34C759"),
        AccountColor(name: "Ciano", hex: "#32ADE6"),
        AccountColor(name: "Azul", hex: "#007AFF"),
        AccountColor(name: "Índigo", hex: "#5856D6"),
        AccountColor(name: "Roxo", hex: "#AF52DE"),
        AccountColor(name: "Rosa", hex: "#FF2D55"),
        AccountColor(name: "Vermelho", hex: "#FF3B30"),
        AccountColor(name: "Marrom", hex: "#A2845E"),
        AccountColor(name: "Cinza", hex: "#8E8E93"),
        AccountColor(name: "Preto", hex: "#1A1A1A")
    ]

    public static let financeIcons: [String] = [
        "building.columns.fill", "creditcard.fill", "wallet.pass.fill", "dollarsign.circle.fill",
        "bag.fill", "chart.pie.fill", "briefcase.fill", "banknote.fill", "cart.fill",
        "bitcoinsign.circle.fill", "centsign.circle.fill", "sterlingsign.circle.fill",
        "yensign.circle.fill", "pills.fill", "cross.case.fill", "airplane", "car.fill",
        "house.fill", "display", "macbook", "iphone", "gamecontroller.fill",
        "graduationcap.fill", "book.fill", "fork.knife", "cup.and.saucer.fill",
        "gift.fill", "heart.fill", "star.fill", "bolt.fill", "flame.fill"
    ]
}
