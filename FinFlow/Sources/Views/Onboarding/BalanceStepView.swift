import SwiftUI

struct BalanceStepView: View {
    @ScaledMetric(relativeTo: .largeTitle) private var iconSize: Double = 52
    @Bindable var viewModel: OnboardingViewModel
    var onFinish: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Theme.Colors.primary.opacity(0.14))
                    .frame(width: 128, height: 128)

                Circle()
                    .fill(Theme.Colors.heroGradient)
                    .frame(width: 96, height: 96)
                    .shadow(color: Theme.Colors.primary.opacity(0.35), radius: 18, x: 0, y: 8)

                Image(systemName: "building.columns.fill")
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text("Configure sua Conta Principal")
                    .font(Theme.Typography.title1)
                    .primaryTextColor()
                    .multilineTextAlignment(.center)

                Text("Defina o nome e o saldo inicial da sua conta bancária ou carteira principal.")
                    .font(Theme.Typography.subheadline)
                    .secondaryTextColor()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            VStack(spacing: 16) {
                GlassTextField(
                    title: "Nome da Conta",
                    placeholder: "Ex: Itaú, Nubank, Carteira...",
                    text: $viewModel.accountName
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text("SALDO ATUAL")
                        .font(Theme.Typography.caption1)
                        .secondaryTextColor()
                        .padding(.leading, 4)

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("R$")
                            .font(Theme.Typography.title2)
                            .foregroundStyle(Theme.Colors.primary)

                        CurrencyTextField(valueInCents: $viewModel.initialBalanceCents)
                            .font(.system(.title2, design: .rounded).bold())
                            .primaryTextColor()
                    }
                    .padding()
                    .glassEffectWithFallback(interactive: true)
                }
            }
            .padding(.horizontal, 4)

            Spacer()

            Button(action: onFinish) {
                Text("Concluir e Acessar Painel")
            }
            .buttonStyle(.customProminentGlass)
            .disabled(!viewModel.isAccountValid)
            .opacity(viewModel.isAccountValid ? 1.0 : 0.45)
        }
        .padding(.vertical, Theme.Layout.standardPadding)
        .adaptiveContainer(maxWidth: Theme.Layout.maxFormWidth)
    }
}
