import SwiftUI

public struct HeroBalanceCardView: View {
    @ScaledMetric(relativeTo: .largeTitle) private var balanceFontSize: Double = 40

    let summary: MonthSummary
    let isBalanceVisible: Bool
    let monthTitle: String

    public init(summary: MonthSummary, isBalanceVisible: Bool, monthTitle: String) {
        self.summary = summary
        self.isBalanceVisible = isBalanceVisible
        self.monthTitle = monthTitle
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Top bar: Label + Month Pill
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.85))
                    Text("PATRIMÔNIO TOTAL")
                        .font(Theme.Typography.caption1)
                        .tracking(0.8)
                        .foregroundStyle(.white.opacity(0.85))
                }

                Spacer()

                Text(monthTitle)
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.16), in: .capsule)
            }

            // Main Balance Display
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("R$")
                        .font(.system(.title2, design: .rounded).weight(.semibold))
                        .foregroundStyle(.white.opacity(0.75))

                    Text(isBalanceVisible ? CurrencyFormatter.formatDecimal(summary.currentBalanceCents) : "••••••")
                        .font(.system(size: balanceFontSize, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }

                HStack(spacing: 6) {
                    Text("Previsto no fim do mês:")
                        .font(Theme.Typography.caption1)
                        .foregroundStyle(.white.opacity(0.75))

                    Text(isBalanceVisible ? CurrencyFormatter.formatCurrency(summary.expectedBalanceCents) : "R$ •••••")
                        .font(Theme.Typography.caption1)
                        .foregroundStyle(.white)
                }
            }

            Divider()
                .overlay(.white.opacity(0.18))

            // Bottom Metrics Row: Income vs Expense
            HStack(spacing: 12) {
                heroMetricPill(
                    title: "Entradas",
                    icon: "arrow.down.left",
                    amountCents: summary.monthIncomeCents,
                    badgeColor: Color(hex: "#34D399")
                )

                heroMetricPill(
                    title: "Saídas",
                    icon: "arrow.up.right",
                    amountCents: summary.monthExpenseCents,
                    badgeColor: Color(hex: "#FB7185")
                )
            }
        }
        .padding(22)
        .background {
            ZStack {
                Theme.Colors.heroGradient

                Circle()
                    .fill(.white.opacity(0.08))
                    .frame(width: 220, height: 220)
                    .offset(x: 130, y: -90)

                Circle()
                    .fill(Color(hex: "#38BDF8").opacity(0.14))
                    .frame(width: 180, height: 180)
                    .blur(radius: 20)
                    .offset(x: -120, y: 100)
            }
            .clipShape(.rect(cornerRadius: Theme.Layout.cardCornerRadius))
        }
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Layout.cardCornerRadius)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.35), .white.opacity(0.05), .white.opacity(0.18)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .allowsHitTesting(false)
        }
        .shadow(color: Color(hex: "#1A5CFF").opacity(0.28), radius: 20, x: 0, y: 10)
        .animation(.snappy, value: isBalanceVisible)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Patrimônio total: \(isBalanceVisible ? CurrencyFormatter.formatCurrency(summary.currentBalanceCents) : "oculto"). Entradas no mês: \(isBalanceVisible ? CurrencyFormatter.formatCurrency(summary.monthIncomeCents) : "oculto"). Saídas no mês: \(isBalanceVisible ? CurrencyFormatter.formatCurrency(summary.monthExpenseCents) : "oculto")."
        )
    }

    private func heroMetricPill(
        title: String,
        icon: String,
        amountCents: Int,
        badgeColor: Color
    ) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(badgeColor.opacity(0.22))
                .frame(width: 34, height: 34)
                .overlay {
                    Image(systemName: icon)
                        .font(.caption.bold())
                        .foregroundStyle(badgeColor)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.Typography.caption2)
                    .foregroundStyle(.white.opacity(0.75))

                Text(isBalanceVisible ? CurrencyFormatter.formatCurrency(amountCents) : "R$ ••••")
                    .font(.system(.subheadline, design: .rounded).bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.white.opacity(0.10), in: .rect(cornerRadius: 14))
    }
}
