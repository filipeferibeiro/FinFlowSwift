import SwiftUI
import SwiftData

public struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = OnboardingViewModel()
    var onFinish: () -> Void

    public init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    public var body: some View {
        BaseView {
            VStack(spacing: 0) {
                topProgressHeader
                    .padding(.horizontal, Theme.Layout.standardPadding)
                    .padding(.top, 12)

                TabView(selection: $viewModel.currentStep) {
                    Tab(value: OnboardingStep.welcome) {
                        WelcomeStepView(onNext: advanceStep)
                    }

                    Tab(value: OnboardingStep.profile) {
                        ProfileStepView(viewModel: viewModel, onNext: advanceStep)
                    }

                    Tab(value: OnboardingStep.balance) {
                        BalanceStepView(viewModel: viewModel, onFinish: completeOnboarding)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .onChange(of: viewModel.currentStep) { _, newStep in
            withAnimation {
                viewModel.validateStepTransition(to: newStep)
            }
        }
    }

    private var topProgressHeader: some View {
        HStack(spacing: 12) {
            if viewModel.currentStep != .welcome {
                Button(action: goBack) {
                    Image(systemName: "chevron.left")
                        .font(.subheadline.bold())
                        .foregroundStyle(Theme.Colors.primary)
                        .frame(width: 40, height: 40)
                        .glassEffectWithFallback(in: .circle, interactive: true)
                }
                .accessibilityLabel("Voltar")
            } else {
                Spacer()
                    .frame(width: 40, height: 40)
            }

            HStack(spacing: 8) {
                ForEach(OnboardingStep.allCases, id: \.rawValue) { step in
                    let isCompletedOrActive = step.rawValue <= viewModel.currentStep.rawValue
                    Capsule()
                        .fill(isCompletedOrActive ? Theme.Colors.primary : Theme.Colors.primary.opacity(0.18))
                        .frame(height: 6)
                        .animation(.snappy, value: viewModel.currentStep)
                }
            }
            .padding(.horizontal, 12)

            Spacer()
                .frame(width: 40, height: 40)
        }
    }

    private func advanceStep() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
            viewModel.nextStep()
        }
    }

    private func goBack() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
            viewModel.previousStep()
        }
    }

    private func completeOnboarding() {
        viewModel.completeOnboarding(in: modelContext)
        withAnimation(.easeInOut) {
            onFinish()
        }
    }
}

#Preview {
    OnboardingView(onFinish: {})
}
