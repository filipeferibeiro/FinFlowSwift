import SwiftUI

public struct TransactionRowView: View {
    let transaction: Transaction
    let isDisintegrating: Bool

    public init(transaction: Transaction, isDisintegrating: Bool) {
        self.transaction = transaction
        self.isDisintegrating = isDisintegrating
    }

    public var body: some View {
        let typeColor = transaction.type.color
        let statusColor = transaction.isPaid ? Theme.Colors.success : Theme.Colors.warning
        let statusText = transaction.isPaid ? "Pago" : "Pendente"

        ZStack {
            PremiumGlassContainer(cornerRadius: Theme.Layout.cornerRadius, padding: 12) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(typeColor.opacity(0.2))
                        .frame(width: 48, height: 48)
                        .overlay {
                            Image(systemName: transaction.type.iconSystemName)
                                .font(.headline)
                                .foregroundStyle(typeColor)
                        }
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Text(transaction.title)
                                .font(Theme.Typography.headline)
                                .primaryTextColor()
                                .lineLimit(1)

                            if transaction.isFixed {
                                Image(systemName: "repeat")
                                    .font(.caption.bold())
                                    .foregroundStyle(Theme.Colors.primary)
                                    .accessibilityLabel("Fixa")
                            }
                        }

                        Text(transaction.accountDisplayTitle)
                            .font(Theme.Typography.caption1)
                            .secondaryTextColor()
                            .lineLimit(1)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(CurrencyFormatter.formatCurrency(transaction.amountCents))
                            .font(Theme.Typography.body)
                            .foregroundStyle(typeColor)

                        HStack(spacing: 4) {
                            Image(systemName: transaction.isPaid ? "checkmark.circle.fill" : "clock.fill")
                                .font(.caption2)
                            Text(statusText)
                                .font(Theme.Typography.caption2)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(statusColor.opacity(0.2), in: .capsule)
                        .foregroundStyle(statusColor)
                    }
                }
            }
            .blur(radius: isDisintegrating ? 20 : 0)
            .scaleEffect(isDisintegrating ? 0.8 : 1.0)
            .opacity(isDisintegrating ? 0.0 : 1.0)
            .animation(.easeIn(duration: 0.25), value: isDisintegrating)

            if isDisintegrating {
                ParticleDustEffect()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(transaction.title), \(transaction.type.title), \(CurrencyFormatter.formatCurrency(transaction.amountCents)), \(transaction.accountDisplayTitle), \(statusText)")
        .accessibilityHint("Toque duas vezes para editar a transação")
    }
}
