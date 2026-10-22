import SwiftUI

struct ProfileStepView: View {
    @ScaledMetric(relativeTo: .largeTitle) private var iconSize: Double = 52
    @Bindable var viewModel: OnboardingViewModel
    var onNext: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Theme.Colors.primary.opacity(0.14))
                    .frame(width: 128, height: 128)

                Circle()
                    .fill(Theme.Colors.heroGradient)
                    .frame(width: 96, height: 96)
                    .shadow(color: Theme.Colors.primary.opacity(0.35), radius: 18, x: 0, y: 8)

                Image(systemName: "person.fill.checkmark")
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)

            VStack(spacing: 10) {
                Text("Personalize seu Perfil")
                    .font(Theme.Typography.title1)
                    .primaryTextColor()
                    .multilineTextAlignment(.center)

                Text("Informe como prefere ser chamado no seu painel financeiro.")
                    .font(Theme.Typography.subheadline)
                    .secondaryTextColor()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            GlassTextField(
                title: "Seu nome ou apelido",
                placeholder: "Ex: Filipe",
                text: $viewModel.name
            )
            .padding(.horizontal, 8)
            .onSubmit {
                if viewModel.isNameValid {
                    onNext()
                }
            }

            Spacer()

            Button(action: onNext) {
                Text("Continuar")
            }
            .buttonStyle(.customProminentGlass)
            .disabled(!viewModel.isNameValid)
            .opacity(viewModel.isNameValid ? 1.0 : 0.45)
        }
        .padding(.vertical, Theme.Layout.standardPadding)
        .adaptiveContainer(maxWidth: Theme.Layout.maxFormWidth)
    }
}
