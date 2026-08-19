import SwiftUI

struct WelcomeStepView: View {
    var onNext: () -> Void
    
    var body: some View {
        VStack(spacing: Theme.Layout.standardPadding * 2) {
            Spacer()
            
            FallbackGlassContainer {
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(Theme.Colors.primary)
                    .padding(24)
                    .glassEffectWithFallback(in: .circle)
                    .accessibilityHidden(true)
            }
            
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
            
            FallbackGlassContainer {
                Button(action: onNext) {
                    Text("Começar")
                }
                .buttonStyle(ProminentGlassButtonStyle())
            }
        }
        .padding(Theme.Layout.standardPadding)
    }
}
