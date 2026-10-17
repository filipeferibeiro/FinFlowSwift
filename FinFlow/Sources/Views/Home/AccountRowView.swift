import SwiftUI

public struct AccountRowView: View {
    let account: Account
    let isBalanceVisible: Bool

    public init(account: Account, isBalanceVisible: Bool) {
        self.account = account
        self.isBalanceVisible = isBalanceVisible
    }

    public var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: account.colorHex))
                    .frame(width: 44, height: 44)

                Image(systemName: account.iconSystemName)
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)

            Text(account.name)
                .font(Theme.Typography.body)
                .primaryTextColor()

            Spacer()

            Text(isBalanceVisible ? CurrencyFormatter.formatCurrency(account.currentBalanceCents) : "R$ •••••")
                .font(Theme.Typography.headline)
                .primaryTextColor()
                .contentTransition(.numericText())
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffectWithFallback(in: .rect(cornerRadius: Theme.Layout.cornerRadius))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(account.name), saldo \(isBalanceVisible ? CurrencyFormatter.formatCurrency(account.currentBalanceCents) : "oculto")")
        .accessibilityHint("Toque duas vezes para editar a conta")
    }
}
