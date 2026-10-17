import SwiftUI

public struct GradientBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @State private var isAnimating = false

    public init() {}

    public var body: some View {
        ZStack {
            Theme.Colors.backgroundBase
                .ignoresSafeArea()

            GeometryReader { proxy in
                ZStack {
                    Circle()
                        .fill(Theme.Colors.primary.opacity(colorScheme == .dark ? 0.18 : 0.09))
                        .frame(width: proxy.size.width * 1.4)
                        .blur(radius: 90)
                        .offset(
                            x: isAnimating ? proxy.size.width * 0.15 : -proxy.size.width * 0.2,
                            y: isAnimating ? -proxy.size.height * 0.15 : -proxy.size.height * 0.05
                        )

                    Circle()
                        .fill(Theme.Colors.secondaryAccent.opacity(colorScheme == .dark ? 0.12 : 0.07))
                        .frame(width: proxy.size.width * 1.1)
                        .blur(radius: 100)
                        .offset(
                            x: isAnimating ? -proxy.size.width * 0.25 : proxy.size.width * 0.25,
                            y: isAnimating ? proxy.size.height * 0.35 : proxy.size.height * 0.15
                        )
                }
            }
            .ignoresSafeArea()
            .accessibilityHidden(true)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 9.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    Group {
        GradientBackground()
            .preferredColorScheme(.light)

        GradientBackground()
            .preferredColorScheme(.dark)
    }
}
