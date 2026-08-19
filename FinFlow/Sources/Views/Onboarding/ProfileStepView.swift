import SwiftUI

struct ProfileStepView: View {
    @Bindable var viewModel: OnboardingViewModel
    var onNext: () -> Void
    
    var body: some View {
        VStack(spacing: Theme.Layout.standardPadding * 2) {
            Spacer()
            
            FallbackGlassContainer {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(Theme.Colors.primary)
                    .padding(24)
                    .glassEffectWithFallback(in: .circle)
                    .accessibilityHidden(true)
            }
            
            VStack(spacing: 16) {
                Text("Como podemos chamar você?")
                    .font(Theme.Typography.title1)
                    .primaryTextColor()
                    .multilineTextAlignment(.center)
                
                VStack(alignment: .leading, spacing: 32) {
                    GlassTextField(title: "Seu nome ou apelido", placeholder: "Ex: Filipe", text: $viewModel.name)
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
            
            FallbackGlassContainer {
                Button(action: onNext) {
                    Text("Continuar")
                }
                .buttonStyle(ProminentGlassButtonStyle())
                .disabled(!viewModel.isNameValid)
                .opacity(viewModel.isNameValid ? 1.0 : 0.5)
            }
        }
        .padding(Theme.Layout.standardPadding)
    }
}
