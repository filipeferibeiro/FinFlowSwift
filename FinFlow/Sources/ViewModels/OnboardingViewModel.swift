import SwiftUI
import SwiftData

@Observable
public final class OnboardingViewModel {
    public var name: String = ""
    public var accountName: String = "Carteira"
    public var initialBalanceCents: Int = 0
    public var currentStep: OnboardingStep = .welcome

    public init() {}

    public var isNameValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public var isAccountValid: Bool {
        !accountName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public func nextStep() {
        switch currentStep {
        case .welcome:
            currentStep = .profile
        case .profile where isNameValid:
            currentStep = .balance
        default:
            break
        }
    }

    public func previousStep() {
        switch currentStep {
        case .balance:
            currentStep = .profile
        case .profile:
            currentStep = .welcome
        case .welcome:
            break
        }
    }

    public func validateStepTransition(to newStep: OnboardingStep) {
        if newStep == .balance && !isNameValid {
            currentStep = .profile
        }
    }

    public func completeOnboarding(in context: ModelContext) {
        let trimmedAccountName = accountName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUserName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        let newAccount = Account(
            name: trimmedAccountName.isEmpty ? "Carteira" : trimmedAccountName,
            initialBalanceCents: initialBalanceCents
        )
        context.insert(newAccount)

        if !trimmedUserName.isEmpty {
            UserDefaults.standard.set(trimmedUserName, forKey: "userName")
        }
    }
}
