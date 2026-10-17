import SwiftUI

public struct MonthOverviewView: View {
    let summary: MonthSummary

    public init(summary: MonthSummary) {
        self.summary = summary
    }

    public var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: 16) {
                overviewMetric(
                    title: "Saldo Atual",
                    amountCents: summary.currentBalanceCents,
                    color: Theme.Colors.textPrimary
                )

                Divider()
                    .frame(height: 32)

                overviewMetric(
                    title: "Previsto (Fim do Mês)",
                    amountCents: summary.expectedBalanceCents,
                    color: Theme.Colors.textSecondary
                )
            }
            .padding(.horizontal, 8)

            FallbackGlassContainer(spacing: 16) {
                HStack(spacing: 16) {
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
                .font(Theme.Typography.caption1)
                .secondaryTextColor()

            Text(CurrencyFormatter.formatCurrency(amountCents))
                .font(.system(.title3, design: .rounded).bold())
                .foregroundStyle(color)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func overviewCard(title: String, icon: String, amountCents: Int, color: Color) -> some View {
        PremiumGlassContainer(cornerRadius: Theme.Layout.cornerRadius, padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.title3.bold())
                        .foregroundStyle(color)

                    Text(title)
                        .font(Theme.Typography.subheadline)
                        .primaryTextColor()
                }

                Text(CurrencyFormatter.formatCurrency(amountCents))
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .primaryTextColor()
                    .contentTransition(.numericText())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}
