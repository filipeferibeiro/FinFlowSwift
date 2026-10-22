import SwiftUI

public struct MonthOverviewView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let summary: MonthSummary
    let isBalanceVisible: Bool

    public init(summary: MonthSummary, isBalanceVisible: Bool = true) {
        self.summary = summary
        self.isBalanceVisible = isBalanceVisible
    }

    public var body: some View {
        PremiumGlassContainer(cornerRadius: Theme.Layout.cornerRadius, padding: horizontalSizeClass == .regular ? 18 : 14) {
            if horizontalSizeClass == .regular {
                HStack(spacing: 16) {
                    currentBalanceColumn

                    Divider()
                        .frame(height: 52)

                    expectedBalanceColumn

                    Divider()
                        .frame(height: 52)

                    incomeFlowColumn

                    Divider()
                        .frame(height: 52)

                    expenseFlowColumn
                }
            } else {
                VStack(spacing: 12) {
                    HStack(spacing: 14) {
                        currentBalanceColumn

                        Divider()
                            .frame(height: 44)

                        expectedBalanceColumn
                    }

                    Divider()

                    HStack(spacing: 14) {
                        incomeFlowColumn

                        Divider()
                            .frame(height: 48)

                        expenseFlowColumn
                    }
                }
            }
        }
    }

    private var currentBalanceColumn: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Saldo atual")
                .font(Theme.Typography.caption2)
                .secondaryTextColor()

            Text(formatValue(summary.currentBalanceCents))
                .font(.system(.headline, design: .rounded).bold())
                .foregroundStyle(
                    summary.currentBalanceCents < 0 ? Theme.Colors.error : Theme.Colors.textPrimary
                )
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .contentTransition(.numericText())

            HStack(spacing: 3) {
                Text("Anterior:")
                    .font(Theme.Typography.caption2)
                    .foregroundStyle(Theme.Colors.textTertiary)

                Text(formatValue(summary.previousBalanceCents))
                    .font(.system(.caption2, design: .rounded).weight(.medium))
                    .secondaryTextColor()
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var expectedBalanceColumn: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Previsto no mês")
                .font(Theme.Typography.caption2)
                .secondaryTextColor()

            Text(formatValue(summary.expectedBalanceCents))
                .font(.system(.headline, design: .rounded).bold())
                .foregroundStyle(
                    summary.expectedBalanceCents < 0 ? Theme.Colors.error : Theme.Colors.primary
                )
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .contentTransition(.numericText())

            HStack(spacing: 3) {
                Text("Balanço:")
                    .font(Theme.Typography.caption2)
                    .foregroundStyle(Theme.Colors.textTertiary)

                Text(formatSignedValue(summary.monthBalanceCents))
                    .font(.system(.caption2, design: .rounded).weight(.semibold))
                    .foregroundStyle(
                        summary.monthBalanceCents >= 0 ? Theme.Colors.success : Theme.Colors.error
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var incomeFlowColumn: some View {
        flowColumn(
            title: "Entradas",
            icon: "arrow.down.left",
            totalCents: summary.monthIncomeCents,
            realizedLabel: "Recebido",
            realizedCents: summary.paidIncomeCents,
            pendingLabel: "Previsto",
            pendingCents: summary.unpaidIncomeCents,
            color: Theme.Colors.success
        )
    }

    private var expenseFlowColumn: some View {
        flowColumn(
            title: "Saídas",
            icon: "arrow.up.right",
            totalCents: summary.monthExpenseCents,
            realizedLabel: "Pago",
            realizedCents: summary.paidExpenseCents,
            pendingLabel: "Previsto",
            pendingCents: summary.unpaidExpenseCents,
            color: Theme.Colors.error
        )
    }

    private func flowColumn(
        title: String,
        icon: String,
        totalCents: Int,
        realizedLabel: String,
        realizedCents: Int,
        pendingLabel: String,
        pendingCents: Int,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2.bold())
                    .foregroundStyle(color)

                Text(title)
                    .font(Theme.Typography.caption2)
                    .secondaryTextColor()

                Spacer(minLength: 4)

                Text(formatValue(totalCents))
                    .font(.system(.caption, design: .rounded).bold())
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .contentTransition(.numericText())
            }

            HStack {
                Text(realizedLabel)
                    .font(Theme.Typography.caption2)
                    .foregroundStyle(Theme.Colors.textTertiary)

                Spacer(minLength: 4)

                Text(formatValue(realizedCents))
                    .font(.system(.caption2, design: .rounded).weight(.medium))
                    .secondaryTextColor()
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            HStack {
                Text(pendingLabel)
                    .font(Theme.Typography.caption2)
                    .foregroundStyle(Theme.Colors.textTertiary)

                Spacer(minLength: 4)

                Text(formatValue(pendingCents))
                    .font(.system(.caption2, design: .rounded).weight(.medium))
                    .secondaryTextColor()
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func formatValue(_ cents: Int) -> String {
        isBalanceVisible ? CurrencyFormatter.formatCurrency(cents) : "R$ ••••"
    }

    private func formatSignedValue(_ cents: Int) -> String {
        guard isBalanceVisible else { return "R$ ••••" }
        let formatted = CurrencyFormatter.formatCurrency(cents)
        return cents > 0 ? "+\(formatted)" : formatted
    }
}
