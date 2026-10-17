import SwiftUI

public struct MonthOverviewView: View {
    let summary: MonthSummary
    let isBalanceVisible: Bool

    public init(summary: MonthSummary, isBalanceVisible: Bool = true) {
        self.summary = summary
        self.isBalanceVisible = isBalanceVisible
    }

    public var body: some View {
        VStack(spacing: 12) {
            // Top Consolidated Balance Bar
            PremiumGlassContainer(cornerRadius: Theme.Layout.cornerRadius, padding: 16) {
                HStack(spacing: 16) {
                    overviewMetric(
                        title: "SALDO ATUAL",
                        amountCents: summary.currentBalanceCents,
                        color: Theme.Colors.primary
                    )

                    Divider()
                        .frame(height: 36)

                    overviewMetric(
                        title: "PREVISTO NO MÊS",
                        amountCents: summary.expectedBalanceCents,
                        color: Theme.Colors.textPrimary
                    )
                }
            }

            // Income & Expense Cards
            FallbackGlassContainer(spacing: 12) {
                HStack(spacing: 12) {
                    overviewCard(
                        title: "Entradas",
                        icon: "arrow.down.left",
                        amountCents: summary.monthIncomeCents,
                        color: Theme.Colors.success
                    )

                    overviewCard(
                        title: "Saídas",
                        icon: "arrow.up.right",
                        amountCents: summary.monthExpenseCents,
                        color: Theme.Colors.error
                    )
                }
            }
        }
    }

    private func overviewMetric(title: String, amountCents: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(Theme.Typography.caption2)
                .secondaryTextColor()

            Text(isBalanceVisible ? CurrencyFormatter.formatCurrency(amountCents) : "R$ •••••")
                .font(.system(.headline, design: .rounded).bold())
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func overviewCard(title: String, icon: String, amountCents: Int, color: Color) -> some View {
        PremiumGlassContainer(cornerRadius: Theme.Layout.cornerRadius, padding: 14) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                    .overlay {
                        Image(systemName: icon)
                            .font(.subheadline.bold())
                            .foregroundStyle(color)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Theme.Typography.caption1)
                        .secondaryTextColor()

                    Text(isBalanceVisible ? CurrencyFormatter.formatCurrency(amountCents) : "R$ •••••")
                        .font(.system(.subheadline, design: .rounded).bold())
                        .primaryTextColor()
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}
