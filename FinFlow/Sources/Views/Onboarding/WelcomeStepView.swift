import SwiftUI

struct WelcomeStepView: View {
    @ScaledMetric(relativeTo: .largeTitle) private var iconSize: Double = 56
    var onNext: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Theme.Colors.primary.opacity(0.14))
                    .frame(width: 136, height: 136)

                Circle()
                    .fill(Theme.Colors.heroGradient)
                    .frame(width: 104, height: 104)
                    .shadow(color: Theme.Colors.primary.opacity(0.35), radius: 20, x: 0, y: 10)

                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: iconSize, weight: .bold))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text("Bem-vindo ao FinFlow")
                    .font(Theme.Typography.largeTitle)
                    .primaryTextColor()
                    .multilineTextAlignment(.center)

                Text("Controle patrimonial, fluxo de caixa e previsibilidade mensal em uma experiência financeira moderna e precisa.")
                    .font(Theme.Typography.body)
                    .secondaryTextColor()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
            }

            VStack(spacing: 12) {
                featureHighlight(
                    icon: "building.columns.fill",
                    title: "Múltiplas Contas",
                    subtitle: "Consolide bancos, carteiras e reservas em um só lugar."
                )
                featureHighlight(
                    icon: "repeat.circle.fill",
                    title: "Recorrência Inteligente",
                    subtitle: "Projete receitas e despesas fixas para os próximos meses."
                )
            }
            .padding(.horizontal, 4)

            Spacer()

            Button(action: onNext) {
                Text("Começar Configuração")
            }
            .buttonStyle(.customProminentGlass)
        }
        .padding(.vertical, Theme.Layout.standardPadding)
        .adaptiveContainer(maxWidth: Theme.Layout.maxFormWidth)
    }

    private func featureHighlight(icon: String, title: String, subtitle: String) -> some View {
        PremiumGlassContainer(cornerRadius: Theme.Layout.cornerRadius, padding: 14) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.Colors.primary.opacity(0.15))
                    .frame(width: 42, height: 42)
                    .overlay {
                        Image(systemName: icon)
                            .font(.headline)
                            .foregroundStyle(Theme.Colors.primary)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Theme.Typography.subheadline)
                        .primaryTextColor()
                    Text(subtitle)
                        .font(Theme.Typography.caption2)
                        .secondaryTextColor()
                }

                Spacer(minLength: 0)
            }
        }
    }
}
