import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    var body: some View {
        if hasCompletedOnboarding {
            // Root Navigation Structure
            MainTabView()
        } else {
            OnboardingView(onFinish: {
                hasCompletedOnboarding = true
            })
            .transition(.opacity)
        }
    }
}

#Preview {
    Group {
        ContentView()
    }
}
