import Foundation

public enum CurrencyFormatter {
    private static let brlCurrencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "BRL"
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter
    }()

    private static let brlDecimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.decimalSeparator = ","
        formatter.groupingSeparator = "."
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter
    }()

    /// Formats an integer amount in cents to BRL currency string (e.g. "R$ 1.250,00").
    public static func formatCurrency(_ cents: Int) -> String {
        let doubleValue = Double(cents) / 100.0
        return brlCurrencyFormatter.string(from: NSNumber(value: doubleValue)) ?? "R$ 0,00"
    }

    /// Formats an integer amount in cents to BRL decimal string without symbol (e.g. "1.250,00").
    public static func formatDecimal(_ cents: Int) -> String {
        let doubleValue = Double(cents) / 100.0
        return brlDecimalFormatter.string(from: NSNumber(value: doubleValue)) ?? "0,00"
    }
}
