import SwiftUI

public struct BaseView<Content: View>: View {
    let content: Content
    
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    public var body: some View {
        ZStack {
            // Reusable background across the entire app
            GradientBackground()
            
            // The actual content of the screen
            VStack(spacing: 0) {
                content
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    BaseView {
        VStack(spacing: Theme.Layout.standardPadding) {
            Text("FinFlow")
                .font(Theme.Typography.largeTitle)
            
            Text("Manage your finances effortlessly")
                .font(Theme.Typography.body)
        }
    }
}
