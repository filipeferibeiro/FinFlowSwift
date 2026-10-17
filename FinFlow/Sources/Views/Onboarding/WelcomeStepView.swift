import SwiftUI

struct WelcomeStepView: View {
    @ScaledMetric(relativeTo: .largeTitle) private var iconSize: Double = 72
    var onNext: () -> Void

    var body: some View {
        VStack(spacing: Theme.Layout.standardPadding * 2) {
            Spacer()

            Image(systemName: "chart.pie.fill")
                .font(.system(size: iconSize))
                .foregroundStyle(Theme.Colors.primary)
                .padding(24)
                .glassEffectWithFallback(in: .circle)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text("Bem-vindo ao FinFlow")
                    .font(Theme.Typography.largeTitle)
                    .primaryTextColor()
                    .multilineTextAlignment(.center)

                Text("Sua vida financeira organizada de forma inteligente. Semelhante ao Organizze, mas com uma experiência moderna.")
                    .font(Theme.Typography.body)
                    .secondaryTextColor()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }

            Spacer()

            Button(action: onNext) {
                Text("Começar")
            }
            .buttonStyle(.customProminentGlass)
        }
        .padding(Theme.Layout.standardPadding)
    }
}
