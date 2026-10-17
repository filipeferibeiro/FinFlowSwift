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
        .onChange(of: viewModel.currentStep) { _, newStep in
            withAnimation {
                viewModel.validateStepTransition(to: newStep)
            }
        }
    }

    private func advanceStep() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            viewModel.nextStep()
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
