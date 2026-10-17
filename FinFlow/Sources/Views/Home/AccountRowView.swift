import SwiftUI

public struct AccountRowView: View {
    let account: Account
    let isBalanceVisible: Bool

    public init(account: Account, isBalanceVisible: Bool) {
        self.account = account
        self.isBalanceVisible = isBalanceVisible
    }

    public var body: some View {
        let accountColor = Color(hex: account.colorHex)

        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 14)
                .fill(accountColor.gradient)
                .frame(width: 46, height: 46)
                .overlay {
                    Image(systemName: account.iconSystemName)
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                .shadow(color: accountColor.opacity(0.3), radius: 6, x: 0, y: 3)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(account.name)
                    .font(Theme.Typography.headline)
                    .primaryTextColor()
                    .lineLimit(1)

                Text("Saldo disponível")
                    .font(Theme.Typography.caption2)
                    .secondaryTextColor()
            }

            Spacer()

            HStack(spacing: 8) {
                Text(isBalanceVisible ? CurrencyFormatter.formatCurrency(account.currentBalanceCents) : "R$ •••••")
                    .font(.system(.headline, design: .rounded).bold())
                    .foregroundStyle(account.currentBalanceCents < 0 ? Theme.Colors.error : Theme.Colors.textPrimary)
                    .contentTransition(.numericText())

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffectWithFallback(in: .rect(cornerRadius: Theme.Layout.cornerRadius))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(account.name), saldo \(isBalanceVisible ? CurrencyFormatter.formatCurrency(account.currentBalanceCents) : "oculto")")
        .accessibilityHint("Toque duas vezes para editar a conta")
    }
}
