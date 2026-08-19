import SwiftUI

struct BalanceStepView: View {
    @Bindable var viewModel: OnboardingViewModel
    var onFinish: () -> Void
    
    var body: some View {
        VStack(spacing: Theme.Layout.standardPadding * 2) {
            Spacer()
            
            FallbackGlassContainer {
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(Theme.Colors.primary)
                    .padding(24)
                    .glassEffectWithFallback(in: .circle)
                    .accessibilityHidden(true)
            }
            
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Crie sua primeira conta")
                        .font(Theme.Typography.title1)
                        .primaryTextColor()
                        .multilineTextAlignment(.center)
                    
                    Text("Dê um nome para a sua conta principal e informe o saldo atual dela.")
                        .font(Theme.Typography.subheadline)
                        .secondaryTextColor()
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    GlassTextField(title: "NOME DA CONTA", placeholder: "Ex: Carteira, Itaú, Nubank...", text: $viewModel.accountName)
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("SALDO INICIAL")
                        .font(Theme.Typography.caption1)
                        .secondaryTextColor()
                        .padding(.leading, 4)
                    
                    HStack {
                        Text("R$")
                            .font(Theme.Typography.title2)
                            .secondaryTextColor()
                        
                        CurrencyTextField(valueInCents: $viewModel.initialBalanceCents)
                            .font(Theme.Typography.title2)
                    }
                    .padding()
                    .glassEffectWithFallback(interactive: true)
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            FallbackGlassContainer {
                Button(action: onFinish) {
                    Text("Concluir e Acessar")
                }
                .buttonStyle(ProminentGlassButtonStyle())
                .disabled(!viewModel.isAccountValid)
                .opacity(viewModel.isAccountValid ? 1.0 : 0.5)
            }
        }
        .padding(Theme.Layout.standardPadding)
    }
}
