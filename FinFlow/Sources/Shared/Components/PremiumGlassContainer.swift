import SwiftUI

public struct PremiumGlassContainer<Content: View>: View {
    let cornerRadius: Double
    let padding: Double
    @ViewBuilder let content: Content

    public init(
        cornerRadius: Double = Theme.Layout.cardCornerRadius,
        padding: Double = Theme.Layout.standardPadding,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    public var body: some View {
        content
            .padding(padding)
            .glassEffectWithFallback(in: RoundedRectangle(cornerRadius: cornerRadius))
    }
}
