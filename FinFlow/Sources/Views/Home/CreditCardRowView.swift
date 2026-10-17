import SwiftUI

public struct CreditCardRowView: View {
    let card: CreditCard
    let invoiceTotalCents: Int
    let isInvoicePaid: Bool
    let usedLimitCents: Int
    let isBalanceVisible: Bool

    public init(
        card: CreditCard,
        invoiceTotalCents: Int,
        isInvoicePaid: Bool,
        usedLimitCents: Int,
        isBalanceVisible: Bool
    ) {
        self.card = card
        self.invoiceTotalCents = invoiceTotalCents
        self.isInvoicePaid = isInvoicePaid
        self.usedLimitCents = usedLimitCents
        self.isBalanceVisible = isBalanceVisible
    }

    public var body: some View {
        let cardColor = Color(hex: card.colorHex)
        let availableLimitCents = max(0, card.limitCents - usedLimitCents)
        let usageRatio = card.limitCents > 0
            ? min(max(Double(usedLimitCents) / Double(card.limitCents), 0.0), 1.0)
            : 0.0

        VStack(spacing: 12) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(cardColor.gradient)
                    .frame(width: 46, height: 46)
                    .overlay {
                        Image(systemName: card.iconSystemName)
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    .shadow(color: cardColor.opacity(0.3), radius: 6, x: 0, y: 3)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(card.name)
                        .font(Theme.Typography.headline)
                        .primaryTextColor()
                        .lineLimit(1)

                    Text("Fecha dia \(card.closingDay) • Vence dia \(card.dueDay)")
                        .font(Theme.Typography.caption2)
                        .secondaryTextColor()
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text(isBalanceVisible ? CurrencyFormatter.formatCurrency(invoiceTotalCents) : "R$ •••••")
                        .font(.system(.headline, design: .rounded).bold())
                        .foregroundStyle(invoiceTotalCents > 0 && !isInvoicePaid ? Theme.Colors.error : Theme.Colors.textPrimary)
                        .contentTransition(.numericText())

                    Text(statusText)
                        .font(Theme.Typography.caption2)
                        .foregroundStyle(statusColor)
                }

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(Theme.Colors.textTertiary)
            }

            if card.limitCents > 0 {
                VStack(spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Theme.Colors.surfaceElevated)

                            Capsule()
                                .fill(usageRatio > 0.85 ? Theme.Colors.error.gradient : cardColor.gradient)
                                .frame(width: max(6, geo.size.width * usageRatio))
                        }
                    }
                    .frame(height: 6)

                    HStack {
                        Text("Limite disponível")
                            .font(Theme.Typography.caption2)
                            .secondaryTextColor()

                        Spacer()

                        Text(isBalanceVisible ? CurrencyFormatter.formatCurrency(availableLimitCents) : "R$ •••••")
                            .font(Theme.Typography.caption2)
                            .primaryTextColor()
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffectWithFallback(in: .rect(cornerRadius: Theme.Layout.cornerRadius))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Cartão \(card.name), fatura atual \(isBalanceVisible ? CurrencyFormatter.formatCurrency(invoiceTotalCents) : "oculta"), \(statusText)"
        )
        .accessibilityHint("Toque duas vezes para ver os detalhes da fatura")
    }

    private var statusText: String {
        if invoiceTotalCents == 0 {
            return "Sem fatura"
        }
        return isInvoicePaid ? "Fatura paga" : "Fatura aberta"
    }

    private var statusColor: Color {
        if invoiceTotalCents == 0 {
            return Theme.Colors.textSecondary
        }
        return isInvoicePaid ? Theme.Colors.success : Theme.Colors.warning
    }
}
