import SwiftUI

public struct TransactionRowView: View {
    let transaction: Transaction
    let isDisintegrating: Bool
    let isAmountVisible: Bool

    public init(
        transaction: Transaction,
        isDisintegrating: Bool,
        isAmountVisible: Bool = true
    ) {
        self.transaction = transaction
        self.isDisintegrating = isDisintegrating
        self.isAmountVisible = isAmountVisible
    }

    public var body: some View {
        let isInvoice = transaction.isCreditCardInvoice
        let typeColor = isInvoice ? Theme.Colors.primary : transaction.type.color
        let statusColor = transaction.isPaid ? Theme.Colors.success : Theme.Colors.warning
        let statusText = isInvoice
            ? (transaction.isPaid ? "Fatura Paga" : "Aberta")
            : (transaction.isPaid ? "Efetivado" : "Pendente")
        let amountPrefix = switch transaction.type {
        case .income: "+ "
        case .expense: "- "
        case .transfer: ""
        }
        let formattedAmount = isAmountVisible
            ? "\(amountPrefix)\(CurrencyFormatter.formatCurrency(transaction.amountCents))"
            : "R$ •••••"
        let iconName = if isInvoice {
            "doc.text.fill"
        } else if transaction.creditCard != nil {
            "creditcard.fill"
        } else {
            transaction.type.iconSystemName
        }

        ZStack {
            PremiumGlassContainer(cornerRadius: Theme.Layout.cornerRadius, padding: 12) {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(typeColor.opacity(0.15))
                        .frame(width: 46, height: 46)
                        .overlay {
                            Image(systemName: iconName)
                                .font(.headline.bold())
                                .foregroundStyle(typeColor)
                        }
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(transaction.title)
                                .font(Theme.Typography.headline)
                                .primaryTextColor()
                                .lineLimit(1)

                            if isInvoice {
                                Text("Fatura")
                                    .font(Theme.Typography.caption2)
                                    .foregroundStyle(Theme.Colors.primary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Theme.Colors.primary.opacity(0.14), in: .capsule)
                            } else if let installmentBadge = transaction.installmentBadgeText {
                                Text(installmentBadge)
                                    .font(Theme.Typography.caption2)
                                    .foregroundStyle(Theme.Colors.primary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Theme.Colors.primary.opacity(0.14), in: .capsule)
                                    .accessibilityLabel("Parcela \(installmentBadge)")
                            } else if transaction.isFixed {
                                Image(systemName: "repeat")
                                    .font(.caption2.bold())
                                    .foregroundStyle(Theme.Colors.primary)
                                    .padding(4)
                                    .background(Theme.Colors.primary.opacity(0.14), in: .circle)
                                    .accessibilityLabel("Recorrente")
                            }
                        }

                        Text(transaction.accountDisplayTitle)
                            .font(Theme.Typography.caption1)
                            .secondaryTextColor()
                            .lineLimit(1)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(formattedAmount)
                            .font(.system(.subheadline, design: .rounded).bold())
                            .foregroundStyle(isInvoice ? Theme.Colors.error : typeColor)

                        HStack(spacing: 4) {
                            Image(systemName: transaction.isPaid ? "checkmark.circle.fill" : "clock.fill")
                                .font(.caption2)
                            Text(statusText)
                                .font(Theme.Typography.caption2)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(statusColor.opacity(0.16), in: .capsule)
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
        .accessibilityLabel("\(transaction.title), \(formattedAmount), \(transaction.accountDisplayTitle), \(statusText)")
        .accessibilityHint(isInvoice ? "Toque duas vezes para pagar ou gerenciar a fatura" : "Toque duas vezes para editar a transação")
    }
}
