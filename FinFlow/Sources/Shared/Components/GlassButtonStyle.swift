import SwiftUI

public struct ProminentGlassButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Typography.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .prominentGlassEffectWithFallback(interactive: true)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

public extension ButtonStyle where Self == ProminentGlassButtonStyle {
    static var customProminentGlass: ProminentGlassButtonStyle {
        ProminentGlassButtonStyle()
    }
}
