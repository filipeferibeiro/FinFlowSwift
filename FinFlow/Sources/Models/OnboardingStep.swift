import Foundation

public enum OnboardingStep: Int, CaseIterable, Hashable, Sendable {
    case welcome = 0
    case profile = 1
    case balance = 2
}
