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
            // We use a custom transition container or a TabView
            TabView(selection: $viewModel.stepIndex) {
                WelcomeStepView(onNext: {
                    withAnimation(.spring) {
                        viewModel.nextStep()
                    }
                })
                .tag(0)
                
                ProfileStepView(viewModel: viewModel, onNext: {
                    withAnimation(.spring) {
                        viewModel.nextStep()
                    }
                })
                .tag(1)
                
                BalanceStepView(viewModel: viewModel, onFinish: {
                    let newAccount = Account(name: viewModel.accountName, initialBalanceCents: viewModel.initialBalanceCents)
                    modelContext.insert(newAccount)
                    
                    UserDefaults.standard.set(viewModel.name, forKey: "userName") // Persist userName
                    viewModel.finishOnboarding()
                    withAnimation(.easeInOut) {
                        onFinish()
                    }
                })
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .onChange(of: viewModel.stepIndex) { oldIndex, newIndex in
            if newIndex == 2 && !viewModel.isNameValid {
                withAnimation {
                    viewModel.stepIndex = 1
                }
            }
        }
    }
}

#Preview {
    OnboardingView(onFinish: {})
}
