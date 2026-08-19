import SwiftUI

@Observable
public final class OnboardingViewModel {
    public var name: String = ""
    public var accountName: String = "Carteira"
    public var initialBalanceCents: Int = 0
    public var stepIndex: Int = 0
    
    public init() {}
    
    public var isNameValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    public var isAccountValid: Bool {
        !accountName.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    public func nextStep() {
        stepIndex += 1
    }
    
    public func previousStep() {
        if stepIndex > 0 {
            stepIndex -= 1
        }
    }
    
    public func finishOnboarding() {
        // Will delegate to a Persistence Service later
        print("Onboarding concluído! Usuário: \(name), Conta: \(accountName), Saldo Inicial: \(initialBalanceCents) centavos")
    }
}
